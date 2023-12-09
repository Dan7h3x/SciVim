# NvimPy

<span style="color:magenta">Ultimate _python_ dev neovim configuration</span>.

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣶⣶⣶⣦⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣤⣤⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⠿⠛⠉⠁⠀⢰⡇⠉⠛⠿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⠟⠋⢀⡀⠀⢀⣠⣤⣿⣷⣴⣷⡀⠹⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣠⡾⠛⠁⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡷⠞⠛⢿⣶⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⠿⠿⠿⠟⠋⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣀⣤⡾⠋⠀⠀⠀⠀⠹⣿⡟⢻⠏⣾⠃⡿⠋⣹⣿⣤⣶⣦⣤⡿⢿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⡶⠶⠟⠋⠁⣀⡀⠀⠀⠀⠀⠀⠈⠻⣾⣠⣇⣼⢁⡞⢉⣿⣿⣿⣿⡏⢰⣿⣿⡋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠸⣿⠟⢷⡄⠀⢠⣶⡶⢀⣿⣿⣿⣷⣾⠁⣾⠋⠀⠀⠙⢿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴
⠀⣴⣶⣶⣦⣄⣹⣿⣟⠻⣆⠘⣿⣿⣿⣿⣿⣿⡿⣿⠀⣿⠀⠀⠀⠿⢸⣿⣯⣴⡶⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⠟⠁
⢸⣿⣿⣿⣿⣿⡟⢻⣿⣿⣿⣶⣤⣽⣿⣿⣿⣿⣧⠸⣧⣿⡄⠀⠀⠀⣈⣉⡉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⠟⠁⠀⣠
⠘⣿⣿⡿⢿⣿⣿⣦⠻⣟⠻⣿⣿⣿⡿⠟⠉⠉⠙⠳⣿⣿⣿⣄⠀⠀⣿⣿⡗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⠟⠁⠀⠀⣴⣯
⠀⠘⢿⣷⣼⣿⣿⣿⣷⣾⣷⣿⠿⠋⠀⠀⠀⠀⠀⠀⠈⠛⢿⣿⣷⣄⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⡾⠋⠁⠀⣠⣴⣿⣷⣤
⠀⠀⠀⠙⠿⢿⣿⣿⣿⠿⠛⠁⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠉⠻⢿⣿⣶⣤⣤⣀⣀⣀⣀⣀⣤⣤⣶⠿⠛⣁⣀⣀⡴⠿⢿⣿⡿⢋⣡
⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⢼⣦⡀⠠⣤⡶⠟⠃⢀⣶⣿⣷⣦⡀⠰⣄⢸⣿⣝⡛⠛⠛⠛⠛⠋⠉⠁⠀⠀⠀⠙⣩⣥⣶⣶⡿⢋⣿⡿⠟
⠀⠀⠀⠙⣿⣶⣛⣵⣶⣄⠀⠙⠇⡀⠀⣶⣦⣀⣾⠁⢻⡟⢿⣿⣦⡈⢻⡟⠻⢯⡳⢤⣀⣠⣴⣶⣶⣦⣤⣼⣿⣭⣍⠉⣁⣀⣈⣉⣀⣿
⠀⢀⣴⣾⣿⠋⢹⣟⣀⣿⣷⣾⣛⣉⣼⣿⣿⣿⣻⣧⡀⠳⠀⠙⢿⣿⣿⣿⣷⣤⣍⣀⡙⣿⣿⣦⣿⣿⣿⠏⠛⠋⢁⣈⣛⣛⣋⣉⣭⣤
⠀⢸⣿⣿⠃⠀⠘⢻⣿⣿⣿⣿⡏⢁⣠⣤⣤⣿⣿⣿⡿⠀⣈⣓⠦⣉⣿⣿⣿⣿⣿⣿⣿⡿⠿⠟⠛⠉⢁⣴⠞⠛⠋⠉⠉⣉⣉⣉⣉⣉
⠀⠈⠛⠁⠀⠀⠀⠘⠛⠛⠛⠛⠛⠛⠛⠉⠉⠛⠛⠙⠓⠚⠛⠛⠃⠀⠀⠉⠉⠙⠛⠒⠚⠒⠒⠛⠛⠚⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛

---

> > Introduction demo

## <video src="https://github.com/Dan7h3x/NvimPy/assets/123359596/646dcef5-2cdc-461c-9665-59c4e2e9884e" width=180 />

> > Latex demo
> > <video src="https://github.com/Dan7h3x/NvimPy/assets/123359596/04ac6d6c-fe7b-4925-979c-eea01c0b2a09" width=180 />

---

> > Requirements (unix/Linux)

- fd (fd-find)
- ripgrep
- npm
- python-pip (python3-pip)
- zathura (pdf viewer for latex)
- ipython (repl)

---

## Installation (Linux)

'''bash
git clone https://github.com/Dan7h3x/NvimPy ~/.config/nvim && cd ~/.config/nvim && rm -rf .git && nvim +checkhealth
'''
