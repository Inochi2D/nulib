<p align="center">
  <img src="nulib.png" alt="NuMem" style="width: 50%; max-width: 512px; height: auto;">
</p>

# NuLib

[![Unit Tests](https://github.com/Inochi2D/nulib/actions/workflows/run_tests.yml/badge.svg)](https://github.com/Inochi2D/nulib/actions/workflows/run_tests.yml)

NuLib is an alternative standard library for the D Programming Language, this standard library focuses
on allowing use of high level D constructs without a garbage collector. Additionally these constructs try
but are not guaranteed to work with phobos constructs to some extent.

In practice this allows you to write mixed GC and no-gc code depending on your needs at any given time,
with nulib building ontop of `numem` for portability. Additionally nulib can be used with `nurt` to go
fully no-gc; with the alternate runtime providing the core required hooks for many D language features.

## Packages

The following packages/modules are provided by NuLib.

| Package           | Module            | Description                              | Supported Platforms |
| ----------------- | ----------------- | ---------------------------------------- | ------------------- |
| `nulib`           | `nulib`           | Core NuLib library                       | All                 |
| `nulib:io`        | `nulib.io`        | File and Network IO                      | 🪟🍎🐧                 |
| `nulib:system`    | `nulib.system`    | System Integration                       | 🪟🍎🐧                 |
| `nulib:threading` | `nulib.threading` | Threading and synchronisation primitives | 🪟🍎🐧                 |

## Why NuLib?

D is an amazing language which bridges both high and low level programming, however with how D's runtime
is constructed, it can be difficult to use DLang outside of its own ecosystem; namely because its runtime
and garbage collector makes cross-language interopability difficult.

The Nu series of libraries aim to fill this gap by both providing tools for users of libphobos and the D
ecosystem, and also providing tools for developers who wish to write libraries used from outside of D.

&nbsp;  
&nbsp;  
&nbsp;  