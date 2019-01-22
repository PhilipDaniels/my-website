---
title: "Comparing PersistentDictionary with SQLite as a Key-Value Store"
date: 2016-06-27T20:19:45Z
draft: false
tags: [c#, sqlite]
---

## Few choices for in-process persistent data stores

When it comes to data storage, developers traditionally have had two
choices:

1. A full-blown database, usually running as separate process. This includes SQL
   databases such as MS-SQL and PostGres, and NoSQL databases such as Mongo.
2. Hold everything in RAM in standard .Net classes such as Dictionary.

The former has the drawback that some installation is usually required, and the
latter doesn't scale to very large datasets.

## The Problem

I recently came across a problem which cried out for a middle ground - I had
about 0.5GB of CSV data to load and iterate over, and I needed rapid access to
any row using its key. And I wanted to wrap this up in a library and not require
its users to install anything. It's surprisingly hard to find solutions to this
problem.

* Load and parse a 0.5GB CSV file (approx 250k rows, 300 columns)
* Provide quick access to any row using the key.
* Iterate all rows.
* Iterate a subset of rows.
* Save the data back out to a CSV file


There was no upper limit to the size of the input data set - which meant that it
might be considerably more than 0.5GB. A solution where I had to hope I didn't
run out of RAM was not good enough.

Here are two alternative techniques that I tried.

## 1) PersistentDictionary<string, string>

PersistentDictionary is an interesting class,
[available as a NuGet package](https://www.nuget.org/packages/Microsoft.Database.Collections.Generic/)
which has an API very similar to the standard .Net **Dictionary<K,V>** class.
This makes it almost trivial to use, but there is one gotcha - you can't store
any type, it has to be something trivially serializable, such as a **string**.
Even **string[]** won't work. But since a CSV file is just a big list of
strings, I simply stored each line in the PersistentDictionary after reading it
in and extracting the key column.

The backing store for the PersistentDictionary is a database called
[ESENT](https://en.wikipedia.org/wiki/Extensible_Storage_Engine), or the
Extensible Storage Engine. It's built in to Windows. If you're anything like me
this will come as a surprise to you - I've been developing on Windows for almost
20 years and had never heard of it :-(

The code to use it is trivial:

```cs
cases = new PersistentDictionary<string, string>(@"C:\temp\mydb")
cases[id] = lineFromCsvFile;
```

## 2) SQLite - one database column

It's possible, of course, to use any SQL database as a simple key-value store.
For this problem, I just did:

```sql
CREATE TABLE cases (id char(8) primary key, data varchar(20000));
```

Where the **data** column is 1 row from the CSV file.

## 3) SQLite - many database columns

Alternatively, when I read in the CSV file I can do the parsing of each line
into its constituent columns and then store each one in a corresponding column
in the SQLLite table:

```sql
CREATE TABLE cases
    (
    id char(8) primary key,
    h1 varchar(200),
    h2 varchar(200),
    h3 varchar(200),
    etc. - approx 300 columns
    );
```

## Results

Confession: when I found PersistentDictionary I thought it would be all I would
need. However testing showed up a serious problem - memory consumption appears
to be proportional to the size of the dataset. Just watch memory usage increase
as the dictionary is populated:

![Persistent Dictionary Memory Usage](pd-mem-usage-250k.png)

It goes up even more when you start iterating over the items. SQLite on the
other hand has superb memory usage behaviour: it does not vary with the size of
the input data set. Here are the results for using the 0.5GB dataset:

Solution              | Read (secs) | Write (secs) | After Load (MB) | After Iterate (MB) |
--------------------- | ----------: | -----------: | --------------: | -----------------: |
PersistentDictionary  |         154 |            7 |             464 |                702 |
SQLite - 1 column     |         147 |            7 |              39 |                 39 |
SQLite - many columns |        1500 |         5950 |              39 |                 39 |

So SQLite wins hands-down when memory usage is considered, and if you use the
one-column approach, essentially turning it into a document store, then its
performance matches that of PersistentDictionary.



