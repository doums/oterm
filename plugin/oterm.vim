" This Source Code Form is subject to the terms of the Mozilla Public
" License, v. 2.0. If a copy of the MPL was not distributed with this
" file, You can obtain one at https://mozilla.org/MPL/2.0/.

let s:save_cpo = &cpo
set cpo&vim

if exists("g:oterm_loaded")
  finish
endif
let g:oterm_loaded = 1

let g:oterm_default = {
      \  'position': 'left',
      \  'size': 40,
      \  'min': 40
      \}

function! s:NormalizeConfig()
  if !exists("g:oterm") || type(g:oterm) != 4
    let g:oterm = g:oterm_default
    return
  endif
	for key in keys(g:oterm_default)
	   if !has_key(g:oterm, key) || type(g:oterm_default[key]) != type(g:oterm[key])
       let g:oterm[key] = g:oterm_default[key]
     endif
	endfor
  if g:oterm.position !~? 'top|/bottom|\right|\left'
    g:oterm.position = 'bottom'
  endif
endfunction

call s:NormalizeConfig()

augroup oterm
  autocmd!
  autocmd BufEnter,TermOpen * call oterm#init_window(expand("<afile>"))
  autocmd BufLeave,TermClose * call oterm#restore_window(expand("<afile>"))
augroup END

command OTerm call oterm#spawn()

" command -nargs=? -complete=dir Ls call fzfTools#Ls(<f-args>)
" noremap <silent> <unique> <script> <Plug>Ls <SID>LsMap
" noremap <SID>LsMap :Ls<CR>
"
" command Buf call fzfTools#Buf()
" noremap <silent> <unique> <script> <Plug>Buf <SID>BufMap
" noremap <SID>BufMap :Buf<CR>
"
" command -nargs=? -complete=file GitLog call fzfTools#GitLog(<f-args>)
" noremap <silent> <unique> <script> <Plug>FGitLog <SID>GitLogMap
" noremap <SID>GitLogMap :GitLog<CR>
"
" command -range GitLogSel call fzfTools#GitLogSel()
" noremap <silent> <unique> <script> <Plug>GitLogSel <SID>GitLogSelMap
" noremap <SID>GitLogSelMap :GitLogSel<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
