# Chooser

This is an interactive selector.

# Build 

```
$ make
```

# How to use

For example, if you need to open a file interactively using the `cat` command, you can use the sample code below.

```
ls | .build/arm64-apple-macosx/debug/chooser | xargs cat
```

And then you can select a file interactively.

```
> (o) LICENSE
  ( ) Makefile
  ( ) Package.resolved
  ( ) Package.swift
  ( ) README.md
  ( ) Sources
  ( ) Tests

```
