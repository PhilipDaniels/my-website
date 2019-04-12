---
title: "Design of Rust APIs (Collections and Iteration)"
date: "2019-04-12"
draft: false
tags: [rust, api, iterators]
---

# Iterators as Input Parameters

This is reasonable:

```rs
fn func1(data: &[i32]) {}
```

But if a function only needs to iterate over its data you can use the
[IntoIterator](https://doc.rust-lang.org/std/iter/trait.IntoIterator.html) trait
to make it more generic:

```rs
fn func2<C>(data: C)
where C: IntoIterator<Item = i32>
```

(Ref: [API Guidelines](https://rust-lang-nursery.github.io/api-guidelines/flexibility.html))

# Constructing and Extending Collections

If you have a type that is a collection type, you should consider implementing the
[FromIterator](https://doc.rust-lang.org/std/iter/trait.FromIterator.html)
and
[Extend](https://doc.rust-lang.org/std/iter/trait.Extend.html) traits.

`FromIterator` allows instances of your collection to be constructed using
[collect](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.collect)
and
`Extend` allows you to easily add the contents of an iterator to a collection
via the [extend](https://doc.rust-lang.org/std/iter/trait.Extend.html#tymethod.extend)
method.

See links above for example implementations, they are simple and obvious.
In particular, `FromIterator` can be implemented by creating an empty collection
and calling `extend` on it.

If a collection type implements `FromIterator<A>` then its static method
`from_iter` builds a value of that type from an iterable producing items
of type `A`.

# Providing Iterators for your collection types

If you have a type which is a collection of items, you should consider
providing the ability to iterate over instances of that type. We then say that
the type is an *iterable*.

* An *iterator* is any type that implements [Iterator](https://doc.rust-lang.org/std/iter/trait.Iterator.html)
* An *iterable* is any type that implements [IntoIterator](https://doc.rust-lang.org/std/iter/trait.IntoIterator.html)
* An *iterator* produces *items*
* The code that receives the items is the *consumer*

(Definitions from *Programming Rust* by Blandy & Orendorff)

## The 3 types of iteration

There are basically 3 ways that you can iterate over something - by move,
by shared reference, and by mutable reference. In the for loop idiom, these
are expressed as follows:

```rs
for item in collection      // move
for item in &collection     // shared reference
for item in &mut collection // mutable reference
```

Note that iterating using moves consumes the original collection.

Under the hood, these calls de-sugar into something like this

```rs
// By move.
let mut iterator = collection.into_iter();
while let Some(item) = iterator.next() {
    // Use the item.
}

// Shared reference.
let mut iterator = (&collection).into_iter();
while let Some(item) = iterator.next() {
    // Use the item.
}

// Mutable reference.
let mut iterator = (&mut collection).into_iter();
while let Some(item) = iterator.next() {
    // Use the item.
}
```

**Note 1** Many collections also implement `iter()` and `iter_mut()` methods which
return iterators. They correspond to the shared and mutable reference examples above,
respectively. The method-equivalent of the move example is handled
by the `into_iter()` method, which is part of the `IntoIterator` trait and described
below. These methods provide a convenient way of getting an iterator when you're
not using the for-loop syntax. You'll often see them used when
[mapping](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.map)
and
[filtering](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.filter)
in a functional style.


**Note 2** Not all collections implement all 3 types of iteration. In particular, iterating by
mutable reference doesn't always make sense, for example you can't iterate over
a [HashMap's](https://doc.rust-lang.org/std/collections/struct.HashMap.html#method.keys) keys
by mutable reference because changing a key would destory the integrity of the
HashMap's internal data structures. But you can iterate over the key-value
pairs, the items returned are tuples with immutable keys but mutable values!
See [HashMap.iter_mut](https://doc.rust-lang.org/std/collections/struct.HashMap.html#method.iter_mut).

## How to implement IntoIterator

Let's imagine we have a very simple collection type called `Solution`, which contains a
vec of `Projects`:

```rs
pub struct Solution {
    projects: Vec<Project>
}

pub struct Project {
    name: String
}
```

If we try to iterate over this


```rs
for proj in sln {
}
```

We will get an error which helpfully reminds us we need to implement `IntoIterator`:

```
22 |     for proj in sln {
   |                 ^^^^ `Solution` is not an iterator
   |
   = help: the trait `std::iter::Iterator` is not implemented for `&Solution`
   = note: required by `std::iter::IntoIterator::into_iter`
```

Here is how to implement the **move** form:

```rs
impl IntoIterator for Solution {
    type Item = Project;
    type IntoIter = ::std::vec::IntoIter<Project>;

    fn into_iter(self) -> Self::IntoIter {
        self.projects.into_iter()
    }
}
```

The line `type Item = Project` says what types of items the iterator will yield.

The next line, `type IntoIter = ::std::vec::IntoIter<Project>` says what type is
produced by the call to `into_iter` - in other words it is naming the **Iterator** type (see terminology above) that `Solution` can produce. `Solution` itself is now an **Iterable**
type thanks to this simple trait implementation.

In this example I don't need to create my own iterator type, I can simply
leverage the vector's already-existing type. But if I couldn't, say my
iteration needs were more complex, this line is the one I would need to target. I
would create a type `SolutionIterator` (say) and specify `type IntoIter = SolutionIterator<Project>`
and then return an instance of `SolutionIterator` from `into_iter`.

With the above in place, for loops of the **move** form now work:

```rs
for proj in sln {
    println!("Project = {}", proj.name);
}
```

Prints

```
Project = Project1
Project = Project2
Project = Project3
```

But unfortunately it destroys the collection. For loops of **shared** or **mutable**
references still do not work:

```
31 |     for proj in &sln {
   |                 ^^^^ `&Solution` is not an iterator
```

We need to add another implementation:

```rs
impl<'s> IntoIterator for &'s Solution {
    type Item = &'s Project;
    type IntoIter = ::std::slice::Iter<'s, Project>;

    fn into_iter(self) -> Self::IntoIter {
        self.projects.iter()
    }
}
```

Note that we need a lifetime specification. This says that the references returned
by the iterator are tied to the lifetime of the `Solution`. This makes sense because the
Projects are owned by the `Solution`.

With this in place we can iterate by **shared reference**, preserving our precious `Solution`
object:

```rs
for proj in &sln {
    println!("Project = {}", proj.name);
}

for proj in &sln {
    println!("Project = {}", proj.name);
}
```

Lastly, as you would expect, iterating by mutable reference requires another
implemention:

```rs
impl<'s> IntoIterator for &'s mut Solution {
    type Item = &'s mut Project;
    type IntoIter = ::std::slice::IterMut<'s, Project>;

    fn into_iter(self) -> Self::IntoIter {
        self.projects.iter_mut()
    }
}
```

The only difference here is that we inserted 'mut' in the references and the
`type` changed from `slice::Iter` to `slice::IterMut`.

Mutable iteration is now possible:

```rs
for proj in &mut sln {
    proj.name = proj.name.to_ascii_uppercase();
    println!("Project = {}", proj.name);
}
```

Prints

```
Project = PROJECT1
Project = PROJECT2
Project = PROJECT3
```

## Implementations in the standard library

The implementations shown above exactly mimic, and were worked out by
copying, the implementations for `Vec` in the standard library.

In the [IntoIterator](https://doc.rust-lang.org/std/iter/trait.IntoIterator.html)
documentation you can see the following implementations (some scrolling
and searching required)

```rs
impl<T> IntoIterator for Vec<T>
impl<'a, T> IntoIterator for &'a Vec<T>
impl<'a, T> IntoIterator for &'a mut Vec<T>
```

Click through to their source to see how they work.

## Complete source code

```rs
pub struct Solution {
    projects: Vec<Project>
}

pub struct Project {
    name: String
}

fn make_example_solution() -> Solution {
    let mut sln = Solution { projects: vec![] };
    sln.projects.push(Project { name: "Project1".to_owned() });
    sln.projects.push(Project { name: "Project2".to_owned() });
    sln.projects.push(Project { name: "Project3".to_owned() });
    sln
}

impl IntoIterator for Solution {
    type Item = Project;
    type IntoIter = ::std::vec::IntoIter<Project>;

    fn into_iter(self) -> Self::IntoIter {
        self.projects.into_iter()
    }
}

impl<'s> IntoIterator for &'s Solution {
    type Item = &'s Project;
    type IntoIter = ::std::slice::Iter<'s, Project>;

    fn into_iter(self) -> Self::IntoIter {
        self.projects.iter()
    }
}

impl<'s> IntoIterator for &'s mut Solution {
    type Item = &'s mut Project;
    type IntoIter = ::std::slice::IterMut<'s, Project>;

    fn into_iter(self) -> Self::IntoIter {
        self.projects.iter_mut()
    }
}

fn main() {
    let mut sln = make_example_solution();

    for proj in &mut sln {
        proj.name = proj.name.to_ascii_uppercase();
        println!("Project = {}", proj.name);
    }
}
```

