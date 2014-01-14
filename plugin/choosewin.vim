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
      \ 'g:choosewin_statusline_replace': 1,
      \ 'g:choosewin_tabline_replace': 1,
      \ 'g:choosewin_active': 0,
      \ 'g:choosewin_hook_enable': 0,
      \ 'g:choosewin_hook': {},
      \ 'g:choosewin_hook_bypass': [],
      \ 'g:choosewin_land_char': ';',
      \ 'g:choosewin_overlay_font_size': 'auto',
      \ 'g:choosewin_overlay_enable': 0,
      \ 'g:choosewin_overlay_shade': 0,
      \ 'g:choosewin_overlay_shade_priority': 100,
      \ 'g:choosewin_overlay_label_priority': 101,
      \ 'g:choosewin_overlay_clear_multibyte': 0,
      \ 'g:choosewin_label_align':   'center',
      \ 'g:choosewin_label_padding': 3,
      \ 'g:choosewin_label_fill':    0,
      \ 'g:choosewin_color_label':
      \      { 'gui': ['DarkGreen', 'white', 'bold'], 'cterm': [ 22, 15,'bold'] },
      \ 'g:choosewin_color_label_current':
      \      { 'gui': ['LimeGreen', 'black', 'bold'], 'cterm': [ 40, 16, 'bold'] },
      \ 'g:choosewin_color_overlay':
      \      { 'gui': ['DarkGreen', 'DarkGreen' ], 'cterm': [ 22, 22 ] },
      \ 'g:choosewin_color_overlay_current':
      \      { 'gui': ['LimeGreen', 'LimeGreen' ], 'cterm': [ 40, 40 ] },
      \ 'g:choosewin_color_other':
      \      { 'gui': ['gray20', 'black'], 'cterm': [ 240, 0] },
      \ 'g:choosewin_color_land':
      \   { 'gui':[ 'LawnGreen', 'Black', 'bold,underline'], 'cterm': ['magenta', 'white'] },
      \ 'g:choosewin_color_shade':
      \   { 'gui':[ '', '#777777'], 'cterm': ['', 'grey'] },
      \ 'g:choosewin_blink_on_land': 1,
      \ 'g:choosewin_return_on_single_win': 0,
      \ 'g:choosewin_label': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      \ 'g:choosewin_keymap': {},
      \ 'g:choosewin_tablabel': '123456789',
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
  autocmd ColorScheme,SessionLoadPost * call choosewin#highlighter#refresh()
augroup END

" KeyMap:
nnoremap <silent> <Plug>(choosewin)
      \ :<C-u>call choosewin#start(range(1, winnr('$')))<CR>

" Command:
command! -bar ChooseWin call choosewin#start(range(1, winnr('$')))

" Finish:
let &cpo = s:old_cpo

" vim: foldmethod=marker
