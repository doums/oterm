## OTerm

A [neovim](https://neovim.io/) plugin to quickly open terminals.

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
The value is the height or the width of the terminal window respectively for `up`/`down` or `left`/`right` expressed as a percentage of the height/width of vim global window.

`min` The minimum lines or columns, depends of the position again, below which the terminal will be spawned in a new tab.

`tab` If equal to `1` the terminal will be spawned in a new tab regardless of the other properties.

#### command
```
:OTerm
```
You can direclty run a process in the spawned terminal
```
:OTerm nnn
```

### mapping
```
nmap <Leader>o <Plug>OTerm
```

### vimscript API
```
call oterm#spawn({ 'command': 'nnn', 'callback': funcref('s:on_exit'), 'layout': { 'left': 40, 'min': 50 }, 'name': 'nnn' })
```

#### `command`
A list of string, the command and its arguments. Optional, default to the user shell.

#### `callback`
A funcref, a function that will be called when the process is finished. Receives as argument the exit status. Optional.

#### `layout`
A dictionary, the terminal window layout, same as `g:oterm`. Optional, default to `g:oterm`.

#### `name`
A string, the name of the terminal buffer. Optional, default to `oterm`.

### license
Mozilla Public License 2.0

