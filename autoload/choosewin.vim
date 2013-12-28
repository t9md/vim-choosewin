
function! s:highlight_preserve(hlname) "{{{1
  redir => HL_SAVE
  execute 'silent! highlight ' . a:hlname
  redir END
  return 'highlight ' . a:hlname . ' ' .
        \  substitute(matchstr(HL_SAVE, 'xxx \zs.*'), "\n", ' ', 'g')
endfunction

function! s:hide_cursor() "{{{1
  highlight Cursor ctermfg=NONE ctermbg=NONE guifg=NONE guibg=NONE
endfunction
"}}}

let s:cw = {}

function! s:cw.setup() "{{{1
  if has_key(self, 'highlighter')
    return
  endif
  let self.highlighter = choosewin#highlighter#new('ChooseWin')
endfunction

function! s:cw.update_status(num) "{{{1
  let g:choosewin_active = a:num
  let &ro = &ro
  redraw
endfunction

function! s:cw.statusline_save() "{{{1
  for win in self.winnums
    let self.wins[win] = getwinvar(win, '&statusline')
  endfor
endfunction

function! s:cw.statusline_restore() "{{{1
  for win in self.winnums
    call setwinvar(win, '&statusline', self.wins[win])
  endfor
endfunction

function! s:cw.statusline_replace() "{{{1
  for win in self.winnums
    let s = self.prepare_statusline(win, g:choosewin_label_align)
    call setwinvar(win, '&statusline', s)
  endfor
  redraw
endfunction

function! s:cw.prepare_statusline(win, align)
  let pad = repeat(' ', g:choosewin_label_padding)
  let win_s = pad . a:win . pad

  if a:align ==# 'left'
    return printf('%%#%s# %s %%#%s# %%= ', self.color_label, win_s, self.color_other)
  elseif a:align ==# 'right'
    return  printf('%%#%s# %%= %%#%s# %s ', self.color_other, self.color_label, win_s)
  elseif a:align ==# 'center'
    let padding = repeat(' ', winwidth(a:win)/2-len(win_s))
    return printf('%%#%s# %s %%#%s# %s %%#%s# %%= ',
          \ self.color_other, padding, self.color_label, win_s, self.color_other)
  endif
endfunction

function! s:cw.start(...) "{{{1
  call self.setup()
  let self.color_label  = self.highlighter.register(g:choosewin_label_color)
  let self.color_other = self.highlighter.register(g:choosewin_other_color)

  if g:choosewin_label_fill
    let self.color_other = self.color_label
  endif

  let self.wins = {}
  let self.winnums = range(1, winnr('$'))

  try
    let hl_cursor_cmd = s:highlight_preserve('Cursor')
    call s:hide_cursor()
    call self.update_status(1)
    echohl PreProc
    echon 'select-window > '
    echohl Normal

    if g:choosewin_statusline_replace
      call self.statusline_save()
      call self.statusline_replace()
    endif

    let num = str2nr(nr2char(getchar()))
    if index(self.winnums, num) ==# -1
      return
    endif
    silent execute  num . 'wincmd w'
  finally
    echo ''
    call self.update_status(0)
    if g:choosewin_statusline_replace
      call self.statusline_restore()
    endif
    execute hl_cursor_cmd
  endtry
endfunction

function! choosewin#start() "{{{1
  call s:cw.start()
endfunction

function! choosewin#set_color() "{{{1
  call s:cw.setup()
  call s:cw.highlighter.refresh()
endfunction

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

" call s:cw.setup()
" echo s:cw.color

" vim: foldmethod=marker
