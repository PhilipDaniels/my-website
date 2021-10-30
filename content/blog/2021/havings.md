---
title: "Handy SQL HAVING Clauses"
date: "2021-10-30"
draft: false
tags: [SQL, HAVING]
---

# Tricks with the 'HAVING' clause

Over the years I have collected a few handy HAVING clauses for SQL work. Here's a summary, with some test cases.

**n.b.** Watch out if you have nulls in your data! Some of these expressions will then degenerate into expressions comparing NULL for equality, which is obviously never true.

We'll need a table for testing:

```SQL
drop table foo; 
create table foo(a int, b int)
```

# Contents

* [All values in B are distinct]({{< ref "#T1" >}})
* [No NULLs in B]({{< ref "#T2" >}})
* [B is all positive or all negative]({{< ref "#T3" >}})
* [min(B) is negative, max(B) isn't]({{< ref "#T4" >}})
* [B has at least one zero]({{< ref "#T5" >}})
* [min(B) or max(B) or both is 0]({{< ref "#T6" >}})
* [B has more than 1 distinct value]({{< ref "#T7" >}})
* [B has only 1 distinct value, or nulls]({{< ref "#T8" >}})
* [B deviates above and below const by the same amount]({{< ref "#T9" >}})
* [Values in B are sequential with no gaps]({{< ref "#T10" >}})


## All values in B are distinct {#T1}

```SQL
delete foo;
insert into foo(a, b) values (1, 0);
insert into foo(a, b) values (1, 1);
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (2, 0);
insert into foo(a, b) values (2, 0);

select a
from foo
group by a
having count(distinct b) = count(b)
```

## No NULLs in B {#T2}

```SQL
delete foo;
insert into foo(a, b) values (1, 0);
insert into foo(a, b) values (1, 1);
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (2, 0);
insert into foo(a, b) values (2, null);

select a
from foo
group by a
having count(*) = count(b)
```

# B is all positive or all negative {#T3}

```SQL
delete foo;
insert into foo(a, b) values (1, 0);
insert into foo(a, b) values (1, 1);
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (2, 1);
insert into foo(a, b) values (2, 2);
insert into foo(a, b) values (2, 3);
insert into foo(a, b) values (3, -1);
insert into foo(a, b) values (3, -2);
insert into foo(a, b) values (3, -3);
insert into foo(a, b) values (4, 4);
insert into foo(a, b) values (4, -2);
insert into foo(a, b) values (4, -3);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);

select a
from foo
group by a
having min(b) * max(b) > 0
```

If you change the above to `having sign(min(b)) = sign(max(b))` then B
can be all positive, all negative, **or all zero**.

# min(B) is negative, max(B) isn't {#T4}

```SQL
delete foo;
insert into foo(a, b) values (1, 0);
insert into foo(a, b) values (1, 1);
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (2, 1);
insert into foo(a, b) values (2, 2);
insert into foo(a, b) values (2, 3);
insert into foo(a, b) values (3, -1);
insert into foo(a, b) values (3, -2);
insert into foo(a, b) values (3, -3);
insert into foo(a, b) values (4, 4);
insert into foo(a, b) values (4, -2);
insert into foo(a, b) values (4, 4);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (6, -10);

select a
from foo
group by a
having min(b) * max(b) < 0
```

# B has at least one zero {#T5}

```SQL
delete foo;
insert into foo(a, b) values (1, 0);
insert into foo(a, b) values (1, 1);
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (2, 1);
insert into foo(a, b) values (2, 2);
insert into foo(a, b) values (2, 3);
insert into foo(a, b) values (3, -1);
insert into foo(a, b) values (3, -2);
insert into foo(a, b) values (3, -3);
insert into foo(a, b) values (4, 4);
insert into foo(a, b) values (4, -2);
insert into foo(a, b) values (4, 4);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (6, -10);

select a
from foo
group by a
having min(abs(b)) = 0
```

# min(B) or max(B) or both is 0 {#T6}

```SQL
delete foo;
insert into foo(a, b) values (1, 0);
insert into foo(a, b) values (1, 1);
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (2, 1);
insert into foo(a, b) values (2, 2);
insert into foo(a, b) values (2, 3);
insert into foo(a, b) values (3, -1);
insert into foo(a, b) values (3, 0);
insert into foo(a, b) values (3, -3);
insert into foo(a, b) values (4, -4);
insert into foo(a, b) values (4, 0);
insert into foo(a, b) values (4, 4);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);

select a
from foo
group by a
having min(b) * max(b) = 0
```

# B has more than 1 distinct value {#T7}

Possibly faster than `count(b) > 1`?

```SQL
delete foo;
insert into foo(a, b) values (1, 0);
insert into foo(a, b) values (1, 1);
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (2, 1);
insert into foo(a, b) values (2, 2);
insert into foo(a, b) values (2, 3);
insert into foo(a, b) values (3, -1);
insert into foo(a, b) values (3, 0);
insert into foo(a, b) values (3, -3);
insert into foo(a, b) values (4, -4);
insert into foo(a, b) values (4, 0);
insert into foo(a, b) values (4, 4);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (6, -10);
insert into foo(a, b) values (7, -10);
insert into foo(a, b) values (7, -10);

select a
from foo
group by a
having min(b) < max(b)
```

# B has only 1 distinct value, or nulls {#T8}

```SQL
delete foo;
insert into foo(a, b) values (1, 0);
insert into foo(a, b) values (1, 1);
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (2, 1);
insert into foo(a, b) values (2, 2);
insert into foo(a, b) values (2, 3);
insert into foo(a, b) values (3, -1);
insert into foo(a, b) values (3, 0);
insert into foo(a, b) values (3, -3);
insert into foo(a, b) values (4, -4);
insert into foo(a, b) values (4, 0);
insert into foo(a, b) values (4, 4);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (6, -10);
insert into foo(a, b) values (7, -10);
insert into foo(a, b) values (7, -10);
insert into foo(a, b) values (9, 99);
insert into foo(a, b) values (9, null);

select a
from foo
group by a
having min(b) = max(b)
```

# B deviates above and below const by the same amount {#T9}

**n.b.** Eliminate the const for deviation around zero.

```SQL
delete foo;
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (1, 3);
insert into foo(a, b) values (1, 8);
insert into foo(a, b) values (2, 1);
insert into foo(a, b) values (2, 2);
insert into foo(a, b) values (2, 3);
insert into foo(a, b) values (3, -1);
insert into foo(a, b) values (3, 0);
insert into foo(a, b) values (3, -3);
insert into foo(a, b) values (4, -4);
insert into foo(a, b) values (4, 0);
insert into foo(a, b) values (4, 14);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (6, -10);
insert into foo(a, b) values (7, -10);
insert into foo(a, b) values (7, -10);
insert into foo(a, b) values (8, null);
insert into foo(a, b) values (8, null);
insert into foo(a, b) values (9, 99);
insert into foo(a, b) values (9, null);

select a
from foo
group by a
having min(b - 5) = -max(b - 5)	-- const = 5
```

# Values in B are sequential with no gaps {#T10}

```SQL
delete foo;
insert into foo(a, b) values (1, 2);
insert into foo(a, b) values (1, 3);
insert into foo(a, b) values (1, 4);
insert into foo(a, b) values (2, -1);
insert into foo(a, b) values (2, 0);
insert into foo(a, b) values (2, 1);
insert into foo(a, b) values (3, 1);
insert into foo(a, b) values (3, 2);
insert into foo(a, b) values (3, 3);
insert into foo(a, b) values (4, -4);
insert into foo(a, b) values (4, 0);
insert into foo(a, b) values (4, 14);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (5, 0);
insert into foo(a, b) values (6, -10);
insert into foo(a, b) values (7, -10);
insert into foo(a, b) values (7, -10);
insert into foo(a, b) values (8, null);
insert into foo(a, b) values (8, null);
insert into foo(a, b) values (9, 99);
insert into foo(a, b) values (9, null);

select a
from foo
group by a
having (max(b) - min(b) + 1) = count(b)
```
