---
title: "[DRAFT] Structuring Rust Programs"
date: "2019-04-17"
draft: true
tags: []
---

# Introduction

This series of articles is aimed at beginner to intermediate level Rust programmers - those who have
mastered the basic sytnax and language features and are starting to wonder how to put together non-
trivial Rust programs. It's written from the perspective of someone who knows a higher-level language
such as C# (my primary language), Java, Python or Javascript. At some point, a developer from those
languages is going to hit a roadblock that they can't get over simply by tweaking code in response
to compiler errors.

I think it's important that the Rust community has a 'HOW-TO' guide for programmers coming from
those languages because they account for such a large proportion of the developer community - probably
at least 80%, and even higher in the line-of-business programming that I tend to do. Although Rust
is sold as a [System programming language](https://en.wikipedia.org/wiki/System_programming_language)
I believe that is an unnecessarily limited worldview - Rust has enough high-level features that
programmers from those languages can feel at home here.[^1]

What is written here encapsulates my struggle as a high-level programmer to become productive with
Rust. At the time of writing, I am only a beginner-to-intermediate level Rust programmer myself, and
some statements, such as leveraging entity-relationship modelling, I have not seen elsewhere. They
represent how I have come to think about Rust programs. You may want to to come up with your own
mental model based off your own skills and experiences; hopefully what I have written here will
help you to do that.

I would also ask the reader to be forgiving about some of my generalizations (such as high-level
languages being class-oriented). The English language is not as precise as a programming language,
and any blog author must carefully walk the line between being precisely correct yet succint enough
to get his point over without drowning the reader in a sea of details and edge cases.

# Aims of these articles

* Describe the difference between high-level languages and Rust
* Describe the problem you will hit at some point if you try and write Rust in the same way that
  you would write a high-level program (hint: it's to do with the borrow checker).
* Describe my mental model for thinking about Rust programs
* Describe several different solutions to the problem
* Introduce a vocabulary to allow Rust programmers to quickly communicate their intent on a higher
  level than just "restructure your program"

Throughout these articles I will use the same example. It's taken from a real-world Rust program
that I wrote, and it was that program which produced the mental epiphany which made me feel I was
"over the hump" in my understanding of how to structure Rust programs - basically, it inspired
this set of articles.

# Contents


## Rust vs high-level languages

C#, Java, Python and Javascript are all similar in that they are all reference-oriented,
garbage collected languages. They emphasize a style of programming which mixes data and functions
together into classes, those classes are then allocated on the heap and referred to via references.
(This means that an object can easily have multiple references to it, an important point.)
Programs create objects while they are running, and at some later point the garbage collector
runs and disposes of all the unreferenced objects, almost magically, without the programmer
having to worry about it.

This model - let's call it object-oriented - has a lot of advantages. I would say the primary
advantage is that it allows the programmer to design classes in isolation without having to worry too
much about how they will later fit into the overall program structure. The programmer's job is
to ask:

* What entities do I have?
* What data do those entities have?
* What methods do I need?
* How do the methods work on the data to maintain the class in a valid state?

A class will typically have one or more constructors which initialize it in a valid state, and will then
be mutated by its methods. As long as those methods ensure that the internal data structures of the
class remain in a valid state we have an entity that can be handed out and passed around and we can
be sure it will remain valid for the duration of the program. (This is just the principle of
encapsulation.) [^2]

In modern development practice, the actual implementation is usually hidden behind an interface, and
the decision as to how to compose the individual classes into a program is left to a
[dependency injection container](https://en.wikipedia.org/wiki/Dependency_injection). This also makes
it possible to make very quick refactorings of the program structure. Furthermore, because the
language is reference-oriented, it is trivial to link up objects into complex graph-like structures,
what Blandy & Orendorff[^3] call a 'sea of objects':

   DIAGRAM

What programmer writing in one of these languages hasn't, at one time or another, thought "I need
to have an X, I'll just add it here as a public property" or decided to add yet another parameter
to a constructor so the object can "get hold of the things I need"?

It's possible to be very productive with this style of programming, which probably accounts for
the success of these languages. Note that the garbage collector is critical for making this work - to
an extent it frees the programmer from having to worry up front how his pieces will fit together
and their lifecycle.

The three main points to take from this are

* Object-orientation mixes data and implementation together
* The high-level languages are reference-oriented and rely on a garbage collector
* This makes it easy to create complex graphs of object references

Rust is different.

Obviously, Rust doesn't have classes or a garbage collector, but I think the difference goes deeper,
I believe it makes sense to think of Rust as a **data-oriented language**, not an object-oriented
one. It's really apparent when you look at Rust data structure declarations:

```rs
```

There are no methods in sight, they will be tucked away in an `impl` block. You can focus purely
on the data. Structs (or enums, or tuples...) are composed into larger and larger values until you
reach the 'root values' in your program.

There's another important difference which is not apparent from the syntax: Rust allocates on the
stack by default, it will only allocate on the heap if you ask it to.

Rust doesn't like object graphs. Object graphs make it unclear who owns an object (in fact ownership
can easily change over the object's lifetime as some references become null). Rust prefers that an
object have a single owner so that it can easily track lifetimes and know when to move and drop an
object. You can make an object graph in Rust, but to do so you'll need to allocate your object on
the heap and use a reference-counting smart pointer such as
[Rc](https://doc.rust-lang.org/std/rc/struct.Rc.html)
or
[Arc](https://doc.rust-lang.org/std/sync/struct.Arc.html).

Rust doesn't like mutability, it prefers immutability. This is basically the borrow checker at work.
If you have some complex data structure, you are allowed to have any number of shared references
pointing to that data structure. So you can iterate over it, search it, clone it or otherwise
manipulate it, **as long as** you don't try to mutate it at the **same time**. The design principle is

> Multiple readers XOR a single writer.[^4]

And it's this which is the key problem I am trying to address in these blog posts.

In C# we are very used to writing code that searches or iterates over object graphs (with LINQ! it's
so easy and powerful) to find some object and then mutates it. This won't work in Rust, the borrow
checker won't let you.










[^1] There is still some way to go Rust is as mature as those other languages. Probably the biggest
drawbacks at the moment are async/await, immaturity of the crate ecosystem, and first-rate IDE
tooling.

[^2] Experienced readers will note that while it is easy to pass objects around, making them
thread-safe is a whole different matter! That's one of the programming challenges Rust is designed
to solve.

[^3] Programming Rust by Jim Blandy and Jason Orendorff, O'Reilly Media, ISBN 978-1-491-92728-1

[^4] Rust did not originate this concept. It is more generally called
[Readers-writer lock](https://en.wikipedia.org/wiki/Readers%E2%80%93writer_lock) and shows up in
C# as [ReaderWriterLockSlim](https://docs.microsoft.com/en-us/dotnet/api/system.threading.readerwriterlockslim?view=netframework-4.7.2)
and even in locking strategies for ACID SQL databases such as Microsoft SQL server.







"restructure your program"
* Leveraging database techniques to design Rust programs
  - ER modelling as inspiration, but trees not graphs
* Don't bother storing the information, just calculate it on demand.
  Allows lots of borrowing, can be more performant.
* Running into a program - mutating while searching or iterating
* SolutionDir -> Solution -> Project -> ProjectToProject examples
* Solutions
    - Think functionally
    - Assemble large trees from small trees returned by functions
    - Iterate, don't mutate
    - Return a handle not a reference (int, key) an example of an ECS
    - Temporary search structure
        - Clone the thing being iterated and pass it down (e.g. as a vec of Rcs)
    - Main OWNERSHIP STRUCTURE plus second NAVIGATION/REFERENCE/TRAVERSAL structure
      which uses & and contains the calculated values
* Getting a mutable reference to something in a deep structure
    similar to the method on vecs split_at_mut for getting two mutable slices?




=================== HOISTING ===================
impl Solution {
    fn get_project_references(&self) -> HashMap<Arc<Project>, Vec<Arc<Project>>> {
        let mut result: HashMap<Arc<Project>, Vec<Arc<Project>>> = HashMap::new();

        for owning_proj in &self.projects {
            // For each project in this solution, look through all of its referenced_project_paths
            for ref_proj in &owning_proj.referenced_project_paths {
                // For each path, try and find the corresponding project in this solution.
                // Note that this calculation is *within this solution* only.
                if let Some(reffed_proj) = self.projects.iter().find(|p| p.path == *ref_proj) {
                    println!("Project {:?} refers to project {:?}", owning_proj.path.display(),  reffed_proj.path.display());

                    // If found, clone its Arc.
                    let owning_proj2 = Arc::clone(owning_proj);
                    let reffed_proj2 = Arc::clone(reffed_proj);
                    let entry = result.entry(owning_proj2).or_default();
                    entry.push(reffed_proj2);
                }
            }
        }

        result
    }

    pub fn calculate_project_references(&mut self) {
        // Mutation of the Solution now occurs at a single point, *after* we
        // have completed all the traversals.
        self.referenced_projects = self.get_project_references();
    }
}



impl PartialEq for Project {
    fn eq(&self, other: &Self) -> bool {
        self.path == other.path
    }
}

impl Eq for Project {}

impl Hash for Project {
    fn hash<H: Hasher>(&self, hasher: &mut H) {
        self.path.hash(hasher);
    }
}


USING INDEXES
=============

    fn add_project(&mut self, mut project: Project) {
//        let mut x = self.get_sln();
//        let x = &mut x;
//        return x;

        if let Some((dir_idx, sln_idx, ownership)) = self.get_solution_that_owns_project(&project.file_info.path) {
            let sln = &mut self.solution_directories[dir_idx].solutions[sln_idx];
            project.ownership = ownership;
            sln.projects.push(project);
        } else {
            eprintln!("Could not associate project {:?} with a solution, ignoring.", &project.file_info.path);
        }
    }

    fn get_sln(&self) -> &Solution {
        &self.solution_directories[0].solutions[0]
    }

    fn get_solution_that_owns_project<P>(&self, project_path: P) -> Option<(usize, usize, ProjectOwnership)>
    where
        P: AsRef<Path>,
    {
        let project_path = project_path.as_ref();
        let parent_dir = project_path.parent().expect("Should always be able to get the parent dir of a project.");

        for ownership_type in vec![ProjectOwnership::Linked, ProjectOwnership::Orphaned] {
            for (dir_idx, sln_dir) in self.solution_directories.iter().enumerate() {
                for (sln_idx, sln) in sln_dir.solutions.iter().enumerate() {

                    match ownership_type {
                        ProjectOwnership::Linked => if sln.refers_to_project(project_path) {
                            return Some((dir_idx, sln_idx, ownership_type))
                        },
                        ProjectOwnership::Orphaned => if sln.file_info.path.is_same_dir(project_path) ||
                                                         sln.file_info.path.is_same_dir(parent_dir)
                        {
                            return Some((dir_idx, sln_idx, ownership_type))
                        },
                        ProjectOwnership::Unknown => unreachable!("There are only 2 ownership types to check.")
                    }
                }
            }
        }

        None
    }
}