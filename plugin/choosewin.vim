" GUARD:
if expand("%:p") ==# expand("<sfile>:p")
  unlet! g:loaded_choosewin
endif
if exists('g:loaded_choosewin')
  finish
endif
let g:loaded_choosewin = 1
let s:old_cpo = &cpo
set cpo&vim

" Main:
let g:choosewin_active = 0
let s:options = {
      \ 'g:choosewin_statusline_replace': 1,
      \ 'g:choosewin_label_align':         'center',
      \ 'g:choosewin_label_padding':       3,
      \ 'g:choosewin_label_fill':          0,
      \ 'g:choosewin_color_label':
      \      { 'gui': ['DarkGreen', 'white', 'bold'], 'cterm': [ 22, 15,'bold'] },
      \ 'g:choosewin_color_label_current': 
      \      { 'gui': ['LimeGreen', 'black', 'bold'], 'cterm': [ 40, 16, 'bold'] },
      \ 'g:choosewin_color_other':
      \      { 'gui': ['gray20', 'black'], 'cterm': [ 240, 0] },
      \ 'g:choosewin_return_on_single_win': 0,
      \ 'g:choosewin_label': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      \ 'g:choosewin_tablabel': '1234567890',
      \ }
      " \ 'g:choosewin_label': ';ABCDEFGHIJKLMNOPQRSTUVWXYZ',

function! s:options_set(options) "{{{
  for [varname, value] in items(a:options)
    if !exists(varname)
      let {varname} = value
    endif
    unlet value
  endfor
endfunction "}}}
call s:options_set(s:options)

augroup plugin-choosewin
  autocmd!
  autocmd ColorScheme,SessionLoadPost * call choosewin#color_set()
augroup END

" KeyMap:
nnoremap <silent> <Plug>(choosewin)
      \ :<C-u>call choosewin#start(range(1, winnr('$')))<CR>

" Command
command! -bar ChooseWin
      \ call choosewin#start(range(1, winnr('$')))

" Finish:
let &cpo = s:old_cpo
" vim: foldmethod=marker
