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
      \  'position': 'bottom',
      \  'size': 40,
      \  'min': 10,
      \  'tab': 0
      \}
```

`position` The position of the spawned terminal window. Can be one of `top`, `bottom`, `left` and `right`. If top or bottom, the terminal will appear at the top/bottom of the vim's global window, **full width**. For right/left, the terminal will appear at the right/left of the vim's global window, **full height**.

`size` The height of the terminal window if `top`/`bottom` or the width if `left`/`right` positions. Expressed as a percentage of the height/width of the vim's global window.

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

### vimscript API
```
call oterm#spawn({ 'command': command, 'callback': funcref('s:on_exit'), 'layout': { 'position': 'bottom', 'size': 40, 'min': 10 }, 'name': 'ls' })
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

