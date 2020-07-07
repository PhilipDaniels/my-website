---
title: "Cloning yourself - a refactoring for thread-spawning Rust types"
date: "2020-07-07"
draft: false
tags: [rust, struct, refactor, pattern, clone, arc, mutex, closure, self, thread]
---

I recently discovered for myself a very nice Rust refactoring (or pattern?) which
produced a very significant simplification in some code I am working on.

I would like to share it with you. I'd say this is an intermediate-level article,
since the Rust compiler won't lead you towards this design, good as its
error messages are.

# The Problem

I wanted to create a Rust type - let's call it `JobEngine` - that would be
used in many places in my program, and from multiple threads. In addition, the
`JobEngine` would use a fixed number of dedicated threads internally to itself
for various tasks.

I wanted all this complexity to be hidden from users of the `JobEngine`.

# The First Attempt

My first code looked like this:

```rs
#[derive(Debug, Clone)]
pub struct JobEngine {
    inner: Arc<JobEngineInner>,
}

#[derive(Debug)]
struct JobEngineInner {
    pending_jobs: Arc<Mutex<VecDeque<Job>>>,
    // other fields...
}
```

The outer/inner types allowed me to hide the `Arc`, which means that
users of the engine can just declare their variables as `JobEngine` and
`clone` as needed before moving the engine into all the threads that
need it. In the real code, `JobEngineInner` has a whole bunch of fields with
[`Arcs`](https://doc.rust-lang.org/std/sync/struct.Arc.html)
and [`Condvars`](https://doc.rust-lang.org/std/sync/struct.Condvar.html).

You may notice the Arc-within-an-Arc. This is not pretty, and turned out
to be necessary because of the implementation of `JobEngineInner`.
`JobEngineInner` is quite complicated. The construction of it requires
several threads to be spawned, with those threads communicating
over channels and needing access to the member fields of `JobEngineInner`.
The real problem was with the **body** of those threads. In order to
avoid lifetime issues the basic pattern became:

* Wrap the required `JobEngineInner` field in an `Arc<Mutex<...>`
* Clone the `Arc`
* Move the cloned value into the closure that is the thread body.

For example, in the following code `pending_jobs` is a field of
`JobEngineInner` that is cloned so that we can `move` it into the
thread. In the real code, there are several more fields that also
need cloning and moving. `job_exec_receiver` is one end of a channel
that also gets moved into the closure, but it's orthogonal to the discussion
because it is not a field of `self` anyway.

```rs
let pending_jobs = self.pending_jobs.clone();
let builder = thread::Builder::new().name("JOB_COMPLETED".into());

builder
    .spawn(move || {
        for job in job_exec_receiver {
            let mut pending_jobs_lock = pending_jobs.lock().unwrap();
            // Lots of code elided: Find the completed job
            // and move it into the completed list
        }
    })
    .expect("Cannot create JOB_COMPLETED thread");
```

You can't pass `&self` into these closure bodies or you'll run into lifetime
issues. That is why we need to Arc-Mutex-wrap and clone all the fields.

It was all a bit messy and very confusing. The design was leading me to a
position where all my struct fields had essentially been hoisted into free
variables, and instead of *methods* operating on `self` I was ending up with a lot of
`Self::` static functions that took everything they needed as parameters. And
sometimes that was essentially most of the `JobEngineInner`'s fields.

It worked, but felt wrong. And I didn't like the nesting of lots of business
logic inside the inline closures. This was always where the bugs were and
I wanted to hoist that code into separate functions to reduce the level of nesting.

**TL;DR** Having a struct spawn a child thread and then call methods on that
struct rather than using inline closures is hard due to lifetimes.

# A Better Solution

Then I had a brainwave, triggered by this I already mentioned above:

> I was ending up with a lot of `Self::` static methods that took everything they needed
> as parameters. And sometimes that was essentially most of the
> `JobEngineInner`'s fields.

So I thought, if I'm already cloning most of this struct's fields, why not just
clone the entire struct? Because all the fields of the struct are in `Arc<Mutex<>>`
already, this is possible (here, `self` is a `JobEngineInner`):

```rs
let me = self.clone();
```

Then I can just `move` the `me` variable into each closure! This turned out
to enable a whole host of simplifications. First I got rid of the `JobEngine/JobEngineInner`
split - this eliminated a lot of method forwarding code too:

```rs
#[derive(Debug, Clone)]
pub struct NewJobEngine {
    pending_jobs: Arc<Mutex<VecDeque<Job>>>,
    // other fields...
}
```

Then, where I previously had inline closure bodies to do the work, these
could finally work as methods on `NewJobEngine`:

```rs
fn run_job_completed_thread(&self, job_exec_receiver: Receiver<Job>) {
    for job in job_exec_receiver {
        let mut pending_jobs_lock = self.pending_jobs.lock().unwrap();
        // Lots of code elided: Find the completed job
        // and move it into the completed list
    }
}
```

(Notice that this method runs forever. In later versions I'll probably have to
deal with catching panics and/or restarting the thread.)

And finally, the magic in `NewJobEngine::new()` where I clone myself
and pass the copy into the spawned threads. I'll post the whole thing
here:

```rs
/// Creates a new job engine that is running and ready to process jobs.
pub fn new(dest_dir: ShadowCopyDestination) -> Self {
    let me = Self {
        dest_dir,
        pending_jobs: Default::default(),
        completed_jobs: Default::default(),
        job_starter_clutch: Default::default(),
        job_added_signal: Default::default(),
    };

    // These channels are used to connect up the various threads.
    let (job_exec_sender, job_exec_internal_receiver) = channel::<Job>();
    let (job_exec_internal_sender, job_exec_receiver) = channel::<Job>();

    // Create the JOB_EXECUTOR thread.
    let builder = thread::Builder::new().name("JOB_EXECUTOR".into());
    let this = me.clone();
    builder
        .spawn(move || {
            this.run_job_executor_thread(job_exec_internal_receiver, job_exec_internal_sender);
        })
        .expect("Cannot create JOB_EXECUTOR thread");

    // Create the JOB_STARTER thread.
    let builder = thread::Builder::new().name("JOB_STARTER".into());
    let this = me.clone();
    builder
        .spawn(move || {
            this.run_job_starter_thread(job_exec_sender);
        })
        .expect("Cannot create JOB_STARTER thread");

    // Create the JOB_COMPLETED thread.
    let builder = thread::Builder::new().name("JOB_COMPLETED".into());
    let this = me.clone();
    builder.spawn(move || {
        this.run_job_completed_thread(job_exec_receiver);
    }).expect("Cannot create JOB_COMPLETED thread");

    me
}
```

The `NewJobEngine` code overall is much simpler due to the reduction of nesting levels,
and the reduced number of functions and vastly reduced number of `clones`.
And the ability to have my worker threads execute methods on my struct fits better
with my mental model of the job engine. I don't like massive inline closures.

Apart from the horrifying synonymity of `Self`, `this`, `me`<sup>*</sup> I was
really pleased with how this turned out. It's always satisfying when you discover a
relatively simple refactoring that allows you to bring a codebase that was getting out
of control back into line.

(*) `self` is a reserved word, so although it looks like you could unambiguously
use a variable called `self` in the `new` function instead of `me`, it turns out
to be forbidden - I guess it keeps the compiler writers' lives simple(ish).
