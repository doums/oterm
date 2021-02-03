" This Source Code Form is subject to the terms of the Mozilla Public
" License, v. 2.0. If a copy of the MPL was not distributed with this
" file, You can obtain one at https://mozilla.org/MPL/2.0/.

let s:save_cpo = &cpo
set cpo&vim

if exists('g:oterm_loaded')
  finish
endif
let g:oterm_loaded = 1

let g:oterm_default = {
      \  'down': 40,
      \  'min': 10,
      \  'tab': 0
      \}

if !exists('g:oterm')
  let g:oterm = g:oterm_default
else
  call oterm#normalize_conf(g:oterm)
endif

augroup oterm
  autocmd!
  autocmd BufEnter,TermOpen * call oterm#init_window(expand('<afile>'))
  autocmd BufLeave,TermClose * call oterm#restore_window(expand('<afile>'))
augroup END

command -nargs=* -complete=shellcmd OTerm call oterm#new(<q-args>)
noremap <silent> <unique> <script> <Plug>OTerm <SID>OTermMap
noremap <SID>OTermMap :OTerm<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
