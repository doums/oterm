" This Source Code Form is subject to the terms of the Mozilla Public
" License, v. 2.0. If a copy of the MPL was not distributed with this
" file, You can obtain one at https://mozilla.org/MPL/2.0/.

if exists('g:oterm_autoloaded')
  finish
endif
let g:oterm_autoloaded = 1

let s:save_cpo = &cpo
set cpo&vim

let s:terminals = []

function! oterm#normalize_conf(layout)
  if type(a:layout) != v:t_dict
    let a:layout = g:oterm_default
    return
  endif
  if !has_key(a:layout, 'up')
        \ && !has_key(a:layout, 'down')
        \ && !has_key(a:layout, 'left')
        \ && !has_key(a:layout, 'right')
    let a:layout.down = 40
  endif
  if !has_key(a:layout, 'min')
        \&& (has_key(a:layout, 'up') || has_key(a:layout, 'down'))
    let a:layout.min = 10
  elseif !has_key(a:layout, 'min')
    let a:layout.min = 40
  endif
  if !has_key(a:layout, 'tab')
    let a:layout.tab = 0
  endif
endfunction

function! s:find_term(bufname)
  if !empty(s:terminals)
    for item in s:terminals
      if item.bufname == a:bufname
        return item
      endif
    endfor
  endif
  return 0
endfunction

function! s:any_term(bufname)
  if !empty(s:terminals)
    for item in s:terminals
      if item.bufname == a:bufname
        return 1
      endif
    endfor
  endif
  return 0
endfunction

function! s:term_index(bufnr)
  if !empty(s:terminals)
    let index = 0
    while index < len(s:terminals)
      if s:terminals[index].bufnr == a:bufnr
        return index
      endif
      let index = index + 1
    endwhile
  endif
  return -1
endfunction

function! s:get_size(layout) abort
  for key in keys(a:layout)
    if key =~# 'up\|down\|left\|right'
      return a:layout[key]
    endif
  endfor
  throw 'Layout invalid!'
endfunction

function! s:find_valid_name(name, ...)
  if a:0 == 0
    if !s:any_term(a:name)
      return a:name
    endif
    return s:find_valid_name(a:name, 1)
  else
    if !s:any_term(a:name..a:1)
      return a:name..a:1
    endif
    return s:find_valid_name(a:name, a:1 + 1)
  endif
endfunction

function! oterm#init_window(bufname)
  if &buftype != 'terminal'
    return
  endif
  let terminal = s:find_term(a:bufname)
  if empty(terminal)
    return
  endif
  echo ''
  let layout = get(terminal, 'layout', g:oterm)
  if !get(layout, 'no_hide_status', 0) && (
        \   get(layout, 'tab', 0)
        \|| get(layout, 'auto_tab', 0)
        \|| has_key(layout, 'up')
        \|| has_key(layout, 'down'))
    let s:laststatus = &laststatus
    set laststatus=0
  endif
  let s:showmode = &showmode
  let s:ruler = &ruler
  let s:showcmd = &showcmd
  let s:cmdheight = &cmdheight
  let s:signcolumn = &signcolumn
  set noshowmode
  set noruler
  set noshowcmd
  set cmdheight=1
  set signcolumn=no
  setlocal nonumber
  setlocal norelativenumber
endfunction

function! oterm#restore_window(bufname)
  if &buftype != 'terminal'
    return
  endif
  if !s:any_term(a:bufname)
    return
  endif
  if exists('s:laststatus')
    let &laststatus = s:laststatus
  endif
  if exists('s:showmode')
    let &showmode = s:showmode
  endif
  if exists('s:ruler')
    let &ruler = s:ruler
  endif
  if exists('s:showcmd')
    let &showcmd = s:showcmd
  endif
  if exists('s:cmdheight')
    let &cmdheight = s:cmdheight
  endif
  if exists('s:signcolumn')
    let &signcolumn = s:signcolumn
  endif
endfunction

function! s:exit_cb(job, status, ...)
  let term_idx = s:term_index(bufnr())
  if term_idx == -1
    throw 'exit_cb: terminal data not found for bufnr '.bufnr()
  endif
  let terminal = s:terminals[term_idx]
  call win_gotoid(terminal.prev_winid)
  if bufexists(terminal.bufnr)
    execute terminal.bufnr.'bdelete!'
  endif
  let i = 0
  if has_key(terminal, 'cb')
    call terminal.cb(a:job, a:status)
  endif
  call remove(s:terminals, term_idx)
endfunction

function! s:create_window(layout)
  if get(a:layout, 'tab')
    tabnew
    return
  endif
  let directions = {
        \ 'up': ['topleft', &lines],
        \ 'down': ['botright', &lines],
        \ 'left': ['vertical topleft', &columns],
        \ 'right': ['vertical botright', &columns] }
  for key in ['up', 'down', 'left', 'right']
    if has_key(a:layout, key)
      let percent = a:layout[key]
      let [cmd, max] = directions[key]
      let size = float2nr(floor(max * (percent / 100.0)))
      if size >= a:layout.min
        execute cmd..size..'new'
      else
        let a:layout.auto_tab = 1
        tabnew
      endif
      return
    endif
  endfor
  throw 'Invalid layout!'
endfunction

function! s:create_term(command, opt)
  if has('nvim')
    let options = { 'on_exit': funcref('s:exit_cb') }
    if has_key(a:opt, 'cwd')
      let options.cwd = a:opt.cwd
    endif
    call termopen(a:command, options)
    execute 'file '.a:opt.name
    let bufnr = bufnr()
    startinsert
  else
    let options = {
          \ 'curwin': 1,
          \ 'term_name': a:opt.name,
          \ 'exit_cb': funcref('s:exit_cb'),
          \ 'term_finish': 'close',
          \ 'term_kill': 'SIGKILL'
          \ }
    if has_key(a:opt, 'cwd')
      let options.cwd = a:opt.cwd
    endif
    let bufnr = term_start(a:command, options)
  endif
  return bufnr
endfunction

function! oterm#spawn(...) abort
  if a:0 > 0
    if type(a:1) != v:t_dict
      call s:print_err('oterm#spawn, wrong argument type, a dictionary expected')
      return
    endif
    if has_key(a:1, 'command')
          \&& type(a:1.command) != v:t_string
          \&& type(a:1.command) != v:t_list
      call s:print_err('oterm#spawn, wrong type for key "command", a string or a list of string expected')
      return
    endif
  endif
  let terminal = { 'prev_winid': win_getid() }
  let layout = deepcopy(g:oterm, 1)
  let command = split(&shell)
  let name = s:find_valid_name('oterm')
  let filetype = 'oterm'
  let options = {}
  if a:0 > 0
    let layout = get(a:1, 'layout', layout)
    let cmd = get(a:1, 'command')
    let filetype = get(a:1, 'filetype', 'oterm')
    if !empty(cmd)
      if type(cmd) == v:t_list
        let cmd = join(cmd)
      endif
      let command = split(&shell) + split(&shellcmdflag) + [cmd]
    endif
    let Cb = get(a:1, 'callback')
    if !empty(Cb)
      let terminal.cb = Cb
    endif
    if has_key(a:1, 'name')
      let name = s:find_valid_name(a:1.name)
    endif
    let cwd = get(a:1, 'cwd')
    if !empty(cwd)
      if !isdirectory(cwd)
        call s:print_err('oterm#spawn, bad value for cwd, a valid directory expected')
        return
      endif
      let options.cwd = cwd
    endif
  endif
  let options.name = name
  call s:create_window(layout)
  let bufnr = s:create_term(command, options)
  call setbufvar(bufnr, '&filetype', filetype)
  let terminal.layout = layout
  let terminal.bufname = name
  let terminal.bufnr = bufnr
  call add(s:terminals, terminal)
  call oterm#init_window(bufname())
  return bufnr
endfunction

function! oterm#new(...)
  let opt = { 'layout': deepcopy(g:oterm, 1) }
  if a:0 > 0
    let opt.command = a:1
  endif
  call oterm#spawn(opt)
endfunction

function! s:print_err(msg)
  echohl ErrorMsg
  echom a:msg
  echohl None
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
