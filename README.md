<!-- markdownlint-configure-file {
  "MD013": {
    "code_blocks": false,
    "tables": false
  },
  "MD033": false,
  "MD041": false
} -->

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

_SciVim_ is a preconfigured `Neovim` IDE layer that brings a scientific
environment for easy and clean starting of the programming/editing journey.

[Demo](#demo)
[Installation](#installation)

## Demo

![Demo1](https://github.com/user-attachments/assets/7dfb65b4-c96d-4eb4-a777-5a1766dfdb20)

### Some Show Cases

-- Functional, nice dashboard:
![Dashboard](https://github.com/user-attachments/assets/1833f53e-a814-4892-b295-e335041c98c9)
-- Fast and full support `nvim-cmp` config:
![Cmp](https://github.com/user-attachments/assets/45385455-c4ba-4400-8832-e88b59dc0e04)

-- Well configured python lsp tools (IDE,multi file support,etc):
![IDEPython](https://github.com/user-attachments/assets/79dee4ec-b0b8-4672-9502-af8ca3c4f940)

![PythonFix](https://github.com/user-attachments/assets/86261f4b-6994-43c1-81e8-73f8414684b5)

![Clean](https://github.com/user-attachments/assets/af5f8ab0-b626-4d5a-858f-4063831aeeec)

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
git clone https://github.com/Dan7h3x/SciVim ~/.config/nvim && cd ~/.config/nvim && rm -rf .git && cd && nvim
```
