<!-- LOGO -->
<br />
<div align="center">
    <a href="https://github.com/Dan7h3x/NvimPy">
    <img src="https://github.com/Dan7h3x/NvimPy/assets/123359596/a8db321e-10d5-4baf-b0a0-4fe74afdad23" alt="Logo" width="400" height="200">
    </a>

<h3 align="center"> Scientific Neovim </h3>

<p align="center">
    Awesome Neovim configuration based on scientific Python + LaTeX needs!
    <br />
    <a href="https://github.com/Dan7h3x/NvimPy/wiki"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/Dan7h3x/NvimPy">Home</a>
    ·
    <a href="https://github.com/Dan7h3x/NvimPy/issues">Report Bug</a>
    ·
    <a href="https://github.com/Dan7h3x/NvimPy/issues">Request Feature</a>
  </p>

</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#introduction">Introduction</a>
      <ul>
        <li><a href="#demo">Latex Demo</a></li>
      </ul>
    </li>
<li>
<a href="#some highlights"> Some highlights </a>
</li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
</details>

<!-- intro -->

## Introduction

I don't have time to explain. See the videos!

<video src=./.Videos/Intro.mp4 width=728 /video>

## Latex Demo
![](./.Videos/Latex.mp4)

## Some highlights

+ `Pyright's bug of unknown user modules fixed.`
+ `Costumized cmp view.`
+ `Complete file management by Neo-tree plugin.`
+ `Full battery IDE configs for python.`
+ `Costumized tokyonight theme.`

<!-- GETTING STARTED -->

## Prerequisites

- [x] `fd` (`fd-find` in ubuntu/debian)
- [x] `ripgrep`
- [x] `npm`
- [x] `python-pip`
- [x] `git`
- [x] `neovim` (**some features works on nightly version**)
- [x] `rubber` (**for building LaTeX files**)
- [x] `Nerd Fonts` (**Font for icons and glyphs**)
- [ ] `zathura` (**for LaTeX preview**)
- [ ] `stylua`

## Installation

- `Linux` & `Mac`

```sh
git clone https://github.com/Dan7h3x/Nvimpy.git ~/.config/nvim && cd ~/.config/nvim && rm -rf .git .Videos && cd ~ && nvim
```

After process of installation, use `nvim +checkhealth` command to get health of configuration.

>> Remember to have functionality of some plugins, use `mason` to install them.
- `Windows`
  <!-- #TODO -->
  \*TODO [+]
