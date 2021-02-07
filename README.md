## OTerm

A [n](https://neovim.io/)/[vim](https://www.vim.org/) plugin to quickly open terminals.

OTerm is a plugin that allows you to open terminals quickly by placing them according to a layout and in an adaptive way.\
It also allows you to run external process direclty in the spawned terminal.

### install

If you use a plugin manager, follow the traditional way.

For example with [vim-plug](https://github.com/junegunn/vim-plug) add this in `.vimrc`/`init.vim`:
```
Plug 'doums/oterm'
```

Then run in vim:
```
:source $MYVIMRC
:PlugInstall
```
If you use vim package `:h packages`.

### configuration

The configuration is optional.
```
" .vimrc/init.vim

let g:oterm = {
      \  'down': 40,
      \  'min': 10,
      \  'tab': 0
      \}
```

`up`, `down`, `left` or `right` sets the position of the spawned terminal window inside the global vim window. If up or down, the terminal will appear at the top/bottom of vim global window, at **full width**. For right/left, the terminal will appear at the right/left of vim global window, at **full height**.\
The value is the height or the width of the terminal window respectively for horizontal or vertical split expressed as a percentage of the height/width of vim global window.

`min` The minimum number of lines or columns, depends on wheter splitted horizontally or vertically, below which the terminal will be spawned in a new tab.

`tab` If equal to `1` the terminal will be spawned in a new tab regardless of the other properties.

### commands
```
:OTerm
:Ot
```
You can direclty run a process in the spawned terminal
```
:OTerm nnn
```

### map
```
nmap <Leader>o <Plug>OTerm
```

### vimscript API
```
call oterm#spawn({ 'command': 'nnn', 'callback': funcref('s:exit_cb'), 'layout': { 'left': 40, 'min': 50 }, 'name': 'nnn' })
```

#### `command`
A string or a list of string, the command and its arguments. Optional, default to the user shell.

#### `callback`
A funcref, a function that will be called when the process exits. Receives as arguments the job data and the exit status. Optional.

#### `layout`
A dictionary, the terminal window layout, same as `g:oterm`. Optional, default to `g:oterm`.

#### `name`
A string, the name of the terminal buffer. Optional, default to `oterm`.

#### `filetype`
A string, the `filetype` of the terminal buffer. Optional, default to `oterm`.

### license
Mozilla Public License 2.0

