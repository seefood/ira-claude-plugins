# Worked Example: The Generator That Emptied Itself

Source bug: https://stackoverflow.com/questions/32078793/annoying-generator-bug

```python
class Foo(object):
    def __init__(self, n):
        self.generator = (x for x in range(n))

    def __iter__(self):
        for e in self.generator:
            yield e

for c in Foo(3):
    print(c)

print(list(Foo(3)))  # works fine: 0, 1, 2
```

```python
class Bar(Foo):
    def __len__(self):
        print("I'm len hear me roar")
        return sum(1 for _ in self.generator)

print(list(iter(Bar(3))))  # prints [] instead of [0, 1, 2]

for c in Bar(3):
    print(c)
```

Adding `__len__` to the subclass makes `list()` return empty. Nothing about `__iter__` changed.

## Entry 1

**Problem Statement**
`list(iter(Bar(3)))` returns `[]`. The identical `Foo(3)` case returns `[0, 1, 2]`. The only difference between `Foo` and `Bar` is the added `__len__` method.

**Hypothesis**
`__len__` is somehow consuming the generator before iteration happens — the underlying generator is one-shot, and something is exhausting it early.

**Experiment**
Move the `print(list(...))` line before the `for` loop, to see whether iteration order (not `__len__`) is the cause.

**Expected Results**
If iteration order is the culprit, calling `list()` first should now produce `[0, 1, 2]` and the subsequent `for` loop would be the one that gets nothing.

**Actual Results**
Still empty. Reordering didn't change anything — ruled out.

## Entry 2

**Problem Statement**
Same as above: `__len__`'s mere presence on the class breaks `list()`, and it isn't an ordering issue.

**Hypothesis**
`list()` calls `len()` on its argument as a sizing hint before iterating. Since `Bar.__len__` drains `self.generator` via `sum(1 for _ in self.generator)`, the generator is already exhausted by the time `list()` starts actually iterating.

**Experiment**
Add a `print` inside `Bar.__len__` and check whether it fires before any iteration output.

**Expected Results**
The `"I'm len hear me roar"` line should print before any element is consumed, confirming `list()` calls `__len__` first.

**Actual Results**
The `len` message printed immediately, before iteration — confirmed. `list()` pre-sizes its result using `__len__` when available, and `Bar.__len__`'s `sum(1 for _ in self.generator)` fully drains the shared generator as a side effect, leaving nothing for `__iter__` to yield afterward.

## Root Cause

`list(obj)` uses `__len__(obj)` as an allocation hint. Because `Bar.__len__` and `Bar.__iter__` (inherited from `Foo`) both read from the same single-use generator, calling `__len__` first consumes it, so iteration then yields nothing. Fix: don't implement `__len__` by consuming the same generator `__iter__` depends on — e.g. materialize the source into a `list`/`tuple` in `__init__`, or track length separately (`n`) instead of draining `self.generator`.
