# Chooser

This is an interactive selector.

# Build executable

Make sure Xcode is installed first.

```
make
```

And then, You can find executable binary `chooser` in .build/debug directory.  
I recommend you to copy the binary into $HOME/bin directory.

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

# More samples for git users

I'm using these snippets as a command alias for daily use.

## Push current git branch with confirmation

```
git branch | grep "\*" | awk "{ print \$2 }" | chooser | xargs -I{} git push origin {}
```

## Change git branch

```
git branch --format='%(refname:short)' | chooser --multiple | xargs -I{} git checkout {}
```

## Delete git branches

```
git branch --format='%(refname:short)' | chooser --multiple | xargs -I{} git branch -d {}
```

