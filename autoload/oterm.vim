" This Source Code Form is subject to the terms of the Mozilla Public
" License, v. 2.0. If a copy of the MPL was not distributed with this
" file, You can obtain one at https://mozilla.org/MPL/2.0/.

let s:save_cpo = &cpo
set cpo&vim

if exists("g:oterm_autoloaded")
  finish
endif
let g:oterm_autoloaded = 1

let s:terminals = []

function! oterm#normalize_conf(layout)
  if type(a:layout) != 4
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
    if has_key(a:layout, 'up') || has_key(a:layout, 'down')
      let a:layout.min = 10
    else
      let a:layout.min = 40
    endif
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

function! s:term_index(jobid)
  if !empty(s:terminals)
    let index = 0
    while index < len(s:terminals)
      if s:terminals[index].jobid == a:jobid
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

function! s:set_win(terminal)
  let layout = get(a:terminal, 'layout', g:oterm)
  if get(layout, 'tab', 0)
    let s:laststatus = &laststatus
    set laststatus=0
  else
    if has_key(layout, 'up')
      let direction = 'K'
    elseif has_key(layout, 'down')
      let direction = 'J'
    elseif has_key(layout, 'left')
      let direction = 'H'
    elseif has_key(layout, 'right')
      let direction = 'L'
    endif
    if mode() != 't'
      execute "normal \<C-w>".direction
    endif
    if has_key(layout, 'up') || has_key(layout, 'down')
      execute "resize ".layout.size
      let s:laststatus = &laststatus
      set laststatus=0
    else
      execute "vertical resize ".layout.size
    endif
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
  call s:set_win(terminal)
  let s:showmode = &showmode
  let s:ruler = &ruler
  let s:showcmd = &showcmd
  let s:cmdheight = &cmdheight
  set noshowmode
  set noruler
  set noshowcmd
  set cmdheight=1
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
endfunction

function! oterm#on_exit(job_id, status, ...)
  let term_idx = s:term_index(a:job_id)
  if term_idx == -1
    return
  endif
  let terminal = s:terminals[term_idx]
  call win_gotoid(terminal.prev_winid)
  execute terminal.bufnr.'bdelete!'
  let i = 0
  if has_key(terminal, 'cb')
    call terminal.cb(a:status)
  endif
  call remove(s:terminals, term_idx)
endfunction

function! oterm#spawn(...)
  if a:0 > 0 && type(a:1) != 4
    call s:Print_err('oterm#new_term, wrong argument type, expected a dictionary')
    return
  endif
  let terminal = { 'jobid': 0, 'prev_winid': win_getid() }
  let layout = g:oterm
  let command = split(&shell)
  let name = s:find_valid_name('oterm')
  if a:0 > 0
    let layout = get(a:1, 'layout', g:oterm)
    let cmd = get(a:1, 'command')
    if empty(cmd)
      let command = split(&shell)
    else
      let command = [&shell, &shellcmdflag, cmd]
    endif
    let Cb = get(a:1, 'callback')
    if !empty(Cb)
      let terminal.cb = Cb
    endif
    if has_key(a:1, 'name')
      let name = s:find_valid_name(a:1.name)
    endif
  endif
  if get(layout, 'tab')
    tabnew
    let terminal.layout = { 'tab': 1 }
  else
    if has_key(layout, 'up') || has_key(layout, 'down')
      let max_size = &lines
    else
      let max_size = &columns
    endif
    let percent = s:get_size(layout)
    let size = float2nr(floor(max_size * (percent / 100.0)))
    if size >= layout.min
      new
      let terminal.layout = { 'size': size }
      call extend(terminal.layout, layout)
    else
      tabnew
      let terminal.layout = { 'tab': 1 }
    endif
  endif
  let jobid = termopen(command, { "on_exit": "oterm#on_exit" })
  execute "file ".name
  let terminal.jobid = jobid
  let terminal.bufname = name
  let terminal.bufnr = bufnr()
  call add(s:terminals, terminal)
  call oterm#init_window(bufname())
  startinsert
endfunction

function! oterm#new(...)
  if a:0 > 0
    let command = split(a:1)
  endif
  call oterm#spawn({ 'command': command, 'layout': g:oterm })
endfunction

function! s:Print_err(msg)
  echohl ErrorMsg
  echom a:msg
  echohl None
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
