---
title: "Some simple Rust async-std examples"
date: "2019-12-01"
draft: false
tags: [rust, async, await, async-std, surf, http]
---

# Introduction

As everyone knows, Rust recently stabilized the `async/await` feature. My first attempt to
convert a little program I had to use it was a dismal failure, (reasons are at the bottom
of this post), so I thought I would step back and write some simple - and I do mean very simple -
examples of how to use await. The final step in this post shows how to download multiple URLs,
in parallel, which was the business problem I was trying to solve in the first place.

I am definitely a learner when it comes to this material, so there may well be better ways to
accomplish some of this - if so, please write a comment and I'll update the post.

The first thing to note is that there are (at least) two competing async eco-systems at the
moment, [Tokio](https://github.com/tokio-rs/tokio)
and [async-std](https://github.com/async-rs/async-std). It appears that you can't mix-and-match
things from one eco-system to the other. I chose to get started with `async-std`
for no other reason that [this video](https://www.youtube.com/watch?v=L7X0vpAU-sU)
helped clear up some of the misconceptions I had.


I'll be including full source code for each example, including `Cargo.toml` and `use`
declarations, and the full source code [is in this git repo](https://github.com/PhilipDaniels/async-std-demo).

# Step 1

The git repo I linked above has a set of tags for each step in this post. You can check out
each tag and run it. In the first step, I add all the dependencies I need for this entire
blog post to `Cargo.toml`:

```ini
[dependencies]
futures = "0.3.1"
rand = "0.7"
async-std = { version = "1.2", features = ["attributes"] }
surf = "1.0"
```

Some people refer to the futures library as `futures-rs` - I don't know why, but when you
hear them do so, it's [futures](https://crates.io/crates/futures)
that you want. We'll use
[rand](https://crates.io/crates/rand) to generate some random
sleep times, and [surf](https://crates.io/crates/surf) to download some web content.

In `main.rs` let's add all the `use` statements we will need (for now and later)
and let's adjust the `main` function to print out how long the program ran for. This
will be a useful sanity-check later on.

```rs
use async_std::task;
use futures::join;
use futures::stream::{FuturesUnordered, StreamExt};
use std::time::{Duration, Instant};
use std::thread;
use rand::distributions::{Distribution, Uniform};

fn main() {
    let start_time = Instant::now();

    println!("Program finished in {} ms", start_time.elapsed().as_millis());
}
```

That's it, now we're all set to start doing something useful.

# Step 2

Let's start by creating two futures and waiting for them to complete. This is just about
the simplest thing we can do. It's important that we explicitly wait - unlike languages
such as C# which have a background runtime to progress tassks, Rust futures are lazy and
do nothing unless polled by a runtime.

In order to exclude unnecessary complications we are going to use the simplest
possible 'work' for our future to do - just sleep for a bit. Because it's so simple
and doesn't perform any sort of IO we also don't have to worry about errors yet.

First the code:

```rs
fn main() {
    let start_time = Instant::now();

    demo_waiting_for_two_async_fns();

    println!("Program finished in {} ms", start_time.elapsed().as_millis());
}

fn demo_waiting_for_two_async_fns() {
    // block_on takes a future and waits for it to complete.
    // Notice that this fn is not `async`, and we are not using
    // an async block either (because we are not calling `await`).
    task::block_on(call_both_sleepers());
}

async fn call_both_sleepers() {
    join!(first_sleeper(), second_sleeper());
}

async fn first_sleeper() {
    sleep_and_print(1, 1000).await;
}

async fn second_sleeper() {
    sleep_and_print(1, 1500).await;
}

/// This utility function simply goes to sleep for a specified time
/// and then prints a message when it is done.
async fn sleep_and_print(future_number: u32, sleep_millis: u64) {
    let sleep_duration = Duration::from_millis(sleep_millis);
    // Note we are using async-std's `task::sleep` here, not
    // thread::sleep. We must not block the thread!
    task::sleep(sleep_duration).await;
    println!("Future {} slept for {} ms on {:?}", future_number, sleep_millis, thread::current().id());
}
```

If you run this code you should see

```
Future 1 slept for 1000 ms on ThreadId(1)
Future 2 slept for 1500 ms on ThreadId(1)
Program finished in 1500 ms
```

Let's disect it. The function `sleep_and_print` is the lowest-level one here,
and it's the one that does the actual sleeping for us. When it's done it simply
prints a message saying so. The `future_number` is just so that we can discriminate
between the invocations. Note the use of
[task::sleep](https://docs.rs/async-std/1.2.0/async_std/task/fn.sleep.html)
from `async-std`.
It's this that means that the thread is not blocked while the function is sleeping,
and hence that the entire program completes in 1500 ms, which is what we want.
If you change to the blocking
[thread::sleep](https://doc.rust-lang.org/std/thread/fn.sleep.html)
you will get something like this:

```
Future 1 slept for 1000 ms on ThreadId(1)
Future 2 slept for 1500 ms on ThreadId(1)
Program finished in 2500 ms
```

The program now takes 2500 ms because the second future was blocked by the first
one calling `thread::sleep`. In the original program, the second future was able to start
executing 'in parallel' because it was not blocked. This brings out an important point -
**don't call blocking APIs from inside async functions!** If you do you will block the
tasks on the thread from making progress.

The functions `first_sleeper`, `second_sleeper` create futures that wait for different
times. Then in `call_both_sleepers` we use the `join!` macro from the `futures` crate
to join them together. Finally we pass `call_both_sleepers` - which is a future - into
`task::block_on`, which runs the tasks to completion.

Frankly I was surprised how much boilerplate was required to get this to work, there's
probably an easier way. But I did get done what I wanted to do - I ran 2 futures
in parallel: the time to complete was the time of the longest duration future, not
the sum of their individual times.

# Step 3

In step 3 we generalize from step 2: instead of trying to run 2 futures in parallel, we
want to run `N`. The easiest way to do this seems to be to use the
[FuturesUnordered](https://docs.rs/futures/0.3.1/futures/stream/futures_unordered/struct.FuturesUnordered.html)
collection type from the `futures` crate.

> Update 14 Dec 2019: Actually, an easier way is to spawn individual
> tasks, a technique that also means we benefit from running on all
> available cores. See Step 7 of this post.

Let's add a new function:

```rs
fn demo_waiting_for_multiple_random_sleeps() {
    // Initialise the random number generator we will use to
    // generate the random sleep times.
    let between = Uniform::from(500..10_000);
    let mut rng = rand::thread_rng();

    // This special collection from the `futures` crate is what we use to
    // hold all the futures; it is designed to efficiently poll the futures
    // until they all complete, (in any order) which we do with a simple
    // loop (see below).
    let mut futures = FuturesUnordered::new();

    // Create 10 futures, each of which should sleep for a random
    // number of milliseconds. None of the futures are doing anything
    // yet, because we are only storing them; we haven't started polling
    // them yet.
    for future_number in 0..10 {
        let sleep_millis = between.sample(&mut rng);
        futures.push(sleep_and_print(future_number, sleep_millis));
    }

    // This loop is how to wait for all the elements in a `FuturesUnordered<T>`
    // to complete. `value_returned_from_the_future` is just the
    // unit tuple, `()`, because we did not return anything from `sleep_and_print`.
    task::block_on(async {
        while let Some(_value_returned_from_the_future) = futures.next().await {
        }
    });
}
```

If we call this from `main`, we get something like this (results will vary due
to the use of the random number generator):

```
Future 6 slept for 726 ms on ThreadId(1)
Future 9 slept for 1233 ms on ThreadId(1)
Future 4 slept for 2013 ms on ThreadId(1)
Future 0 slept for 2056 ms on ThreadId(1)
Future 3 slept for 3072 ms on ThreadId(1)
Future 7 slept for 5316 ms on ThreadId(1)
Future 2 slept for 6328 ms on ThreadId(1)
Future 8 slept for 6374 ms on ThreadId(1)
Future 5 slept for 6725 ms on ThreadId(1)
Future 1 slept for 7936 ms on ThreadId(1)
Program finished in 7936 ms
```

This is exactly the behaviour I was looking for - it looks like we have multiple
futures executing, and the overall time is equal to the longest sleep time. This also
shows that the overhead of using `async/await` is very small (less than 1 ms).

# Step 4

So far our futures have not returned any values. In this step, we build on the code
introduced in step 3 by making one simple change - we introduce a new version of
`sleep_and_print` which returns a value to the caller.

```rs
async fn sleep_and_print_and_return_value(future_number: u32, sleep_millis: u64) -> u32 {
    let sleep_duration = Duration::from_millis(sleep_millis);
    task::sleep(sleep_duration).await;
    println!("Future {} slept for {} ms on thread {:?}", future_number, sleep_millis, thread::current().id());

    future_number * 10
}

fn demo_waiting_for_multiple_random_sleeps_with_return_values() {
    let between = Uniform::from(500..10_000);
    let mut rng = rand::thread_rng();

    let mut cf = FuturesUnordered::new();

    for future_number in 0..10 {
        let random_millis = between.sample(&mut rng);
        cf.push(sleep_and_print_and_return_value(future_number, random_millis));
    }

    // The async block borrows a mutable reference to `sum`, allowing us to
    // add up all the values returned from the future.
    let mut sum = 0;
    task::block_on(async {
        while let Some(value_returned_from_the_future) = cf.next().await {
            sum += value_returned_from_the_future;
        }
    });

    println!("Sum of all values returned = {}", sum);
}
```

When we run this we get this output:

```
Future 9 slept for 1095 ms on thread ThreadId(1)
Future 1 slept for 1378 ms on thread ThreadId(1)
Future 6 slept for 3577 ms on thread ThreadId(1)
Future 3 slept for 3874 ms on thread ThreadId(1)
Future 8 slept for 4946 ms on thread ThreadId(1)
Future 5 slept for 7034 ms on thread ThreadId(1)
Future 0 slept for 7172 ms on thread ThreadId(1)
Future 7 slept for 7511 ms on thread ThreadId(1)
Future 4 slept for 8079 ms on thread ThreadId(1)
Future 2 slept for 9114 ms on thread ThreadId(1)
Sum of all values returned = 450
Program finished in 9114 ms
```

# Step 5

Step 5 is a simple extension of step 4 - instead of returning a `u32` we return
a `Result<T,E>` - many futures will do this, so we need to know how to handle them.

```rs
async fn sleep_and_print_and_return_error(future_number: u32, sleep_millis: u64) -> Result<u32, String> {
    let sleep_duration = Duration::from_millis(sleep_millis);
    task::sleep(sleep_duration).await;
    println!("Future {} slept for {} ms on thread {:?}", future_number, sleep_millis, thread::current().id());

    if future_number % 2 == 0 {
        Ok(future_number * 10)
    } else {
        Err(format!("It didn't work for future {}", future_number))
    }
}

fn demo_waiting_for_multiple_random_sleeps_with_errors() {
    let between = Uniform::from(500..10_000);
    let mut rng = rand::thread_rng();

    let mut futures = FuturesUnordered::new();

    for future_number in 0..10 {
        let random_millis = between.sample(&mut rng);
        futures.push(sleep_and_print_and_return_error(future_number, random_millis));
    }

    // Now, `value_returned_from_the_future` is a `Result<u32, String>` so
    // we must take care to pattern match on it.
    let mut sum = 0;
    task::block_on(async {
        while let Some(value_returned_from_the_future) = futures.next().await {
            match value_returned_from_the_future {
                Ok(value) => sum += value,
                Err(e) => println!("    Got error back: {}", e),
            }
        }
    });

    println!("Sum of all values returned = {}", sum);
}
```

When we run this we get this output:

```
Future 7 slept for 1445 ms on thread ThreadId(1)
    Got error back: It didn't work for future 7
Future 4 slept for 1561 ms on thread ThreadId(1)
Future 3 slept for 1583 ms on thread ThreadId(1)
    Got error back: It didn't work for future 3
Future 1 slept for 2048 ms on thread ThreadId(1)
    Got error back: It didn't work for future 1
Future 6 slept for 4138 ms on thread ThreadId(1)
Future 0 slept for 4886 ms on thread ThreadId(1)
Future 9 slept for 5718 ms on thread ThreadId(1)
    Got error back: It didn't work for future 9
Future 2 slept for 6562 ms on thread ThreadId(1)
Future 8 slept for 7209 ms on thread ThreadId(1)
Future 5 slept for 9591 ms on thread ThreadId(1)
    Got error back: It didn't work for future 5
Sum of all values returned = 200
Program finished in 9591 ms
```

# Step 6

Step 6 is the final step. In the previous steps I demonstrated how to run multiple
futures and await all their results, handling errors when required. Now we can use
those techniques to do some useful work. Let's try and download a bunch of URLs
in parallel.

The code is surprisingly simple. We bring in the
[surf](https://github.com/http-rs/surf)
library to handle the HTTP GETs, and there is one other innovation, we
use `collect` to build our set of futures but we could just as easily have
iterated over the urls collection and pushed them one by one into the
`futures` collection.

```rs
async fn download_url(url: &str) -> Result<String, surf::Exception> {
    println!("Downloading {} on thread {:?}", url, thread::current().id());

    // Code taken directly from the example for `surf`.
    let mut result = surf::get(url).await?;
    let body = result.body_string().await?;

    println!("    Downloaded {}, returning body of length {} ", url, body.len());
    Ok(body)
}

fn demo_downloading_urls() {
    let urls = vec![
        "https://www.sharecast.com/equity/Anglo_American",
        "https://www.sharecast.com/equity/Associated_British_Foods",
        "https://www.sharecast.com/equity/Admiral_Group",
        "https://www.sharecast.com/equity/Aberdeen_Asset_Management",
        "https://www.sharecast.com/equity/Aggreko",
        "https://www.sharecast.com/equity/Ashtead_Group",
        "https://www.sharecast.com/equity/Antofagasta",
        "https://www.sharecast.com/equity/Aviva",
        "https://www.sharecast.com/equity/AstraZeneca",
        "https://www.sharecast.com/equity/BAE_Systems",
        "https://www.sharecast.com/equity/Babcock_International_Group",
        "https://www.sharecast.com/equity/British_American_Tobacco",
        "https://www.sharecast.com/equity/Balfour_Beatty",
        "https://www.sharecast.com/equity/Barratt_Developments",
        "https://www.sharecast.com/equity/BG_Group",
        "https://www.sharecast.com/equity/British_Land_Company",
        "https://www.sharecast.com/equity/BHP_Group",
        "https://www.sharecast.com/equity/Bunzl",
        "https://www.sharecast.com/equity/BP",
        "https://www.sharecast.com/equity/Burberry_Group",
        "https://www.sharecast.com/equity/BT_Group",
    ];

    // This time let's make our FuturesUnordered value by collecting
    // a set of futures.
    let mut cf = urls.iter()
        .map(|url| download_url(url))
        .collect::<FuturesUnordered<_>>();

    task::block_on(async {
        while let Some(return_val) = cf.next().await {
            match return_val {
                Ok(body) => {
                    // Possibly do something useful with the body of the request here.
                },
                Err(e) => println!("    Got error {:?}", e),
            }
        }
    });
}
```

When we run this program, we get something like this:

```
Downloading https://www.sharecast.com/equity/Anglo_American on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Associated_British_Foods on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Admiral_Group on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Aberdeen_Asset_Management on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Aggreko on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Ashtead_Group on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Antofagasta on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Aviva on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/AstraZeneca on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/BAE_Systems on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Babcock_International_Group on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/British_American_Tobacco on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Balfour_Beatty on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Barratt_Developments on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/BG_Group on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/British_Land_Company on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/BHP_Group on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Bunzl on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/BP on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/Burberry_Group on thread ThreadId(1)
Downloading https://www.sharecast.com/equity/BT_Group on thread ThreadId(1)
    Downloaded https://www.sharecast.com/equity/BT_Group, returning body of length 83555
    Downloaded https://www.sharecast.com/equity/BP, returning body of length 82642
    Downloaded https://www.sharecast.com/equity/Aviva, returning body of length 82924
    Downloaded https://www.sharecast.com/equity/Anglo_American, returning body of length 83110
    Downloaded https://www.sharecast.com/equity/Antofagasta, returning body of length 82406
    Downloaded https://www.sharecast.com/equity/Bunzl, returning body of length 81577
    Downloaded https://www.sharecast.com/equity/BHP_Group, returning body of length 82203
    Downloaded https://www.sharecast.com/equity/Admiral_Group, returning body of length 82780
    Downloaded https://www.sharecast.com/equity/BAE_Systems, returning body of length 83328
    Downloaded https://www.sharecast.com/equity/Barratt_Developments, returning body of length 83751
    Downloaded https://www.sharecast.com/equity/Balfour_Beatty, returning body of length 83645
    Downloaded https://www.sharecast.com/equity/Ashtead_Group, returning body of length 83060
    Downloaded https://www.sharecast.com/equity/Burberry_Group, returning body of length 83147
    Downloaded https://www.sharecast.com/equity/Aggreko, returning body of length 81857
    Downloaded https://www.sharecast.com/equity/British_American_Tobacco, returning body of length 84589
    Downloaded https://www.sharecast.com/equity/British_Land_Company, returning body of length 83755
    Downloaded https://www.sharecast.com/equity/AstraZeneca, returning body of length 83023
    Downloaded https://www.sharecast.com/equity/Aberdeen_Asset_Management, returning body of length 28780
    Downloaded https://www.sharecast.com/equity/Associated_British_Foods, returning body of length 85075
    Downloaded https://www.sharecast.com/equity/Babcock_International_Group, returning body of length 87022
    Downloaded https://www.sharecast.com/equity/BG_Group, returning body of length 73655
Program finished in 6622 ms
```

The program finishes a lot faster compared to making the requests in series.

And that's it! I hope this proves useful to others; comments and improvements
are welcome.

# Step 7

A couple of weeks after writing the first version of this post I figured out a way
to run multiple futures on multiple cores. We don't need `FuturesUnordered`, we can
just spawn as many tasks as we need then wait for them all to complete. `async-std's`
executor will distribute the tasks across all available cores. Here is a simple
example, based on downloading URLs again:

```rs
fn demo_downloading_urls_on_multiple_threads() {
    let mut tasks = Vec::with_capacity(URLS.len());

    for url in URLS.iter() {
        let url = url.to_string();
        tasks.push(task::spawn(async move {
            match download_url(&url).await {
                Ok(body) => { // Possibly do something useful with the body of the request here.
                },
                Err(e) => println!("    Got error {:?}", e),
            }
        }))
    }

    task::block_on(async {
        for t in tasks {
            t.await;
        }
    });
}
```

When we run this program we get something like this (note the different ThreadIds):

```
Downloading https://www.sharecast.com/equity/Anglo_American on thread ThreadId(9)
Downloading https://www.sharecast.com/equity/Associated_British_Foods on thread ThreadId(4)
Downloading https://www.sharecast.com/equity/Admiral_Group on thread ThreadId(7)
Downloading https://www.sharecast.com/equity/Ashtead_Group on thread ThreadId(5)
Downloading https://www.sharecast.com/equity/Aviva on thread ThreadId(6)
Downloading https://www.sharecast.com/equity/BAE_Systems on thread ThreadId(2)
Downloading https://www.sharecast.com/equity/Barratt_Developments on thread ThreadId(3)
Downloading https://www.sharecast.com/equity/Aggreko on thread ThreadId(8)
Downloading https://www.sharecast.com/equity/Babcock_International_Group on thread ThreadId(2)
Downloading https://www.sharecast.com/equity/BP on thread ThreadId(4)
...
```

The total execution time is similar to the single-threaded version, but that's only
because we don't have a lot of work to do. In a heavily loaded server this technique
is obviously preferable.

### Gotchas

I could not fix the program I was originally trying to asyncify (it's not listed here).
The problem was that it was using
[reqwest](https://docs.rs/reqwest/0.10.0-alpha.2/reqwest/)
rather than
[surf](https://github.com/http-rs/surf). When I tried to use `reqwest::get` I got
an error `Error(Connect, Custom { kind: Other, error: "no current reactor" })`.

The author notes that `reqwest` is undergoing development which will mean
breaking changes, but I don't know if that means this error will go away.

It would be unfortunate (to say the least) if Rust libraries only work on certain
async runtimes - not to mention hugely confusing for people trying to learn
the ropes. But things are still very new, I think it is going to take several
months for things to begin to settle down, documentation to be updated etc.
