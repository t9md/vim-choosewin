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
let s:options = {
      \ 'g:choosewin_label_fill': 0,
      \ 'g:choosewin_color_label':
      \   { 'gui': ['DarkGreen', 'white', 'bold'], 'cterm': [ 22, 15,'bold'] },
      \ 'g:choosewin_color_label_current':
      \   { 'gui': ['LimeGreen', 'black', 'bold'], 'cterm': [ 40, 16, 'bold'] },
      \ 'g:choosewin_color_overlay':
      \   { 'gui': ['DarkGreen', 'DarkGreen' ], 'cterm': [ 22, 22 ] },
      \ 'g:choosewin_color_overlay_current':
      \   { 'gui': ['LimeGreen', 'LimeGreen' ], 'cterm': [ 40, 40 ] },
      \ 'g:choosewin_color_other':
      \   { 'gui': ['gray20', 'black'], 'cterm': [ 240, 0] },
      \ 'g:choosewin_color_land':
      \   { 'gui':[ 'LawnGreen', 'Black', 'bold,underline'], 'cterm': ['magenta', 'white'] },
      \ 'g:choosewin_color_shade':
      \   { 'gui':[ '', '#777777'], 'cterm': ['', 'grey'] },
      \ }

function! s:options_set(options)
  for [varname, value] in items(a:options)
    if !exists(varname)
      let {varname} = value
    endif
    unlet value
  endfor
endfunction

call s:options_set(s:options)

augroup plugin-choosewin
  autocmd!
  autocmd ColorScheme,SessionLoadPost * call choosewin#color#refresh()
augroup END

" KeyMap:
nnoremap <silent> <Plug>(choosewin)
      \ :<C-u>call choosewin#start(range(1, winnr('$')))<CR>

" Command:
function! s:win_all()
  return range(1, winnr('$'))
endfunction

command! -bar ChooseWin
      \ call choosewin#start(s:win_all())
command! -bar ChooseWinSwap
      \ call choosewin#start(s:win_all(), {'swap': 1, 'swap_stay': 0 })
command! -bar ChooseWinSwapStay
      \ call choosewin#start(s:win_all(), {'swap': 1, 'swap_stay': 1 })

" Finish:
let &cpo = s:old_cpo

" vim: foldmethod=marker
