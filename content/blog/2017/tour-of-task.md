---
title: "Summary of Stephen Cleary's 'Tour of Task' Series"
date: 2017-11-06T20:19:45Z
draft: false
tags: [c#, task, async, TPL, parallelism]
---

# Summary of Stephen Cleary's 'A Tour of Task' articles
[The first article](http://blog.stephencleary.com/2014/04/a-tour-of-task-part-0-overview.html)

* Task as used by [TPL](https://docs.microsoft.com/en-us/dotnet/standard/parallel-programming/task-parallel-library-tpl)
  is completely different to Task as used by `async`.
* The vast majority of Task members have no place in async code.
* There are two types of Task
** Delegate tasks, which have code to run
** Promise tasks, which represent an event or signal (e.g. IO or timer based)
* Most TPL code uses Delegate tasks across multiple threads,, most async code uses Promise tasks
  which don't tie up a thread.

## Task Constructors
[Original Article](http://blog.stephencleary.com/2014/05/a-tour-of-task-part-1-constructors.html)

* These can only create Delegate tasks. Promise tasks are created using the `async` keyword.
* They create tasks that are not running. Don't use them.
* Use [Parallel](https://msdn.microsoft.com/en-us/library/system.threading.tasks.parallel)
  or [PLINQ](https://docs.microsoft.com/en-us/dotnet/standard/parallel-programming/parallel-linq-plinq)
  for parallel code.
* For dynamic task parallelism, you can use `Task.Run` or `Task.Factory.StartNew`.

## Task Status
[Original Article](http://blog.stephencleary.com/2014/06/a-tour-of-task-part-3-status.html)

* Rarely used except for debugging, normally wait for the task to complete and extract the
  results.

## Waiting
[Original Article](http://blog.stephencleary.com/2014/10/a-tour-of-task-part-5-wait.html)

* All `Wait` operations block the calling thread until the task completes, so they are never
  used with Promise tasks. (Blocking on a Promise is a cause of deadlocks).
* `Wait` is rather simple: it will block the calling thread until the task completes, a timeout
  occurs, or the wait is cancelled. If the wait is cancelled, then `Wait` raises an
  `OperationCanceledException`. If a timeout occurs, then `Wait` returns false. If the task completes
  in a failed or canceled state, then `Wait` wraps any exceptions into an `AggregateException`. Note
  that a canceled task will raise an `OperationCanceledException` wrapped in an `AggregateException`,
  whereas a canceled wait will raise an unwrapped `OperationCanceledException`.
* `WaitAll` and `WaitAny` are similar, but for collections of `Task`.
* Use `await` instead of `Wait`.

## Results
[Original Article](http://blog.stephencleary.com/2014/12/a-tour-of-task-part-6-results.html)

* Only exists on `Task<T>` type.
* Blocks like `Wait`, with the same drawbacks.
* Wraps any exceptions inside an `AggregateException`, which makes error handling complicated.
* `GetAwaiter().GetResult` blocks like `Result`, but does not wrap any exceptions. This works
  for both `Task<T>` and `Task`. So if you have to block, this is better.
* The vast majority of time, `await` should be used to get the result of a Promise task.

## Continuations
[Original Article](http://blog.stephencleary.com/2015/01/a-tour-of-task-part-7-continuations.html)

* Don't use `ContinueWith` - the defaults are all wrong. Just use `await`.
* Don't use `TaskFactory.ContinueWhenAny` - use `await Task.WhenAny(...)`
* Don't use `TaskFactory.ContinueWhenAll` - use `await Task.WhenAll(...)`

## Starting Delegate tasks
[The obsolete way](http://blog.stephencleary.com/2015/02/a-tour-of-task-part-8-starting.html)
and
[The correct way](http://blog.stephencleary.com/2015/03/a-tour-of-task-part-9-delegate-tasks.html)

* Don't use `Start`.
* Don't use `RunSynchronously`. It runs on the current thread.
* Don't use `Task.Factory.StartNew` unless you are doing [dynamic task parallelism]
  (https://msdn.microsoft.com/en-us/library/ff963551.aspx) (which is very rare)
* DO USE `Task.Run`. Its `CancellationToken` is mostly useless, but the other overloads are good
  for queueing work to the thread pool.

## Starting Promise tasks
[Original Article](http://blog.stephencleary.com/2015/04/a-tour-of-task-part-10-promise-tasks.html)

* `Task.Delay` is the async equivalent of `Thread.Sleep`, use it in preference. `Thread.Sleep`
  actually puts the current thread to sleep for a time (which means it is not doing any useful
  work). `Task.Delay` allows the thread to be used to do other work (perhaps for other tasks).
* `Task.FromResult` can be used to create a completed task with a result value.
* `Task.FromException` and `Task.FromCancelled` can be used to return completed tasks in those
  states (.Net 4.6 API).


# Summary of Stephen Cleary's async intro
[Original Article](http://blog.stephencleary.com/2012/02/async-and-await.html)

* Avoid `async void` methods, except for event handlers. They can't be awaited.
* When you `await` a built-in awaitable, the current "context" is captured and later
  re-applied when the rest of the async method is executed. Context means UI context, ASP.Net
  request context, or thread-pool context.
* The context overhead can be avoided by doing `await FooAsync(parms).ConfigureAwait(false)`
  (you should do this by default unless you know you need the original context).

