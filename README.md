
<a href="https://dotfyle.com/Dan7h3x/scivim"><img src="https://dotfyle.com/Dan7h3x/scivim/badges/plugins?style=flat" /></a>
<a href="https://dotfyle.com/Dan7h3x/scivim"><img src="https://dotfyle.com/Dan7h3x/scivim/badges/leaderkey?style=flat" /></a>
<a href="https://dotfyle.com/Dan7h3x/scivim"><img src="https://dotfyle.com/Dan7h3x/scivim/badges/plugin-manager?style=flat" /></a>

`README` _*WIP*_

<div align="center">

<sup>Wellcome to:</sup>

<a href="https:www.github.com/Dan7h3x/SciVim">
  <div>
    <img src="https://github.com/user-attachments/assets/a525d6c9-0e76-4a08-993b-03ceb4965b65" width="230" alt="SciVim" />
  </div>
  <b>
    SciVim is an elegant, fast, easy to use and configure premaded on scientific tools.
  </b>
  <div>
    <sup> Enjoy and Collaborate.</sup>
  </div>
</a>

<hr />
</div>
_SciVim_ is a preconfigured `Neovim` IDE layer that brings a scientific
environment for easy and clean starting of the programming/editing journey.

[Demo](#demo)
[Installation](#installation)
[Plugins](#plugins)

## Demo

![Demo1](https://github.com/user-attachments/assets/c60b25cd-4254-4df7-8418-86affc4e0dff)

## Installation

First just move your config to safe location or just use:

```sh
# must
mv ~/.config/nvim{,.bak}
# also for fresh installation
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}
```

For `Linux/Unix` with having all _*dependencies*_ installed, just copy and
execute the command below:

```sh
git clone https://github.com/Dan7h3x/SciVim --branch=stable ~/.config/nvim && cd ~/.config/nvim && rm -rf .git && cd && nvim
```

## Language Servers

+ bashls
+ html
+ lua_ls
+ ty,ruff
+ texlab
+ typst_lsp
+ clangd
+ zls
+ rust-analyzer
