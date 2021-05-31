# coc-java-dependency

An extension for [coc.nvim](https://github.com/neoclide/coc.nvim) to provide
additional Java project explorer features for the
[jdt.ls](https://github.com/eclipse/eclipse.jdt.ls) language server that is
loaded by [coc-java](https://github.com/neoclide/coc-java). This extension uses
the jar from
[vscode-java-dependency](https://github.com/Microsoft/vscode-java-dependency).

## Prerequisites

You must have [coc-java](https://github.com/neoclide/coc-java) installed first
and the Java language server is working properly.

```
:CocInstall coc-java
```

This project uses the tree widget from
[vim-widgets](https://github.com/uzxmx/vim-widgets), so you also need to install
it. For [vim-plug](https://github.com/junegunn/vim-plug) users, add below:

```
Plug 'uzxmx/vim-widgets'
```

## Installation

Run below command in vim.

```
:CocInstall coc-java-dependency
```

For the first time, it will download dependencies from
[vscode-java-dependency](https://github.com/Microsoft/vscode-java-dependency)
releases.

## How to use

To open the project dependency explorer, execute:

```
:JavaDependencyOpen
```

To close it, execute:

```
:JavaDependencyClose
```

To focus on current file in the explorer, execute:

```
:JavaDependencyFocus
```

## Available commands

The following commands are available:

* `java.dependency.downloadJdtlsExtension [version]`: download the default (or
  specific) version of the Java language server extension.

## License

[MIT License](LICENSE)
