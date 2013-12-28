function! s:plog(msg) "{{{1
  call vimproc#system('echo "' . PP(a:msg) . '" >> ~/vim.log')
endfunction

function! s:highlight_preserve(hlname) "{{{1
  redir => HL_SAVE
  execute 'silent! highlight ' . a:hlname
  redir END
  return 'highlight ' . a:hlname . ' ' .
        \  substitute(matchstr(HL_SAVE, 'xxx \zs.*'), "\n", ' ', 'g')
endfunction

function! s:echohl(hlname) "{{{1
  execute 'echohl' a:hlname
endfunction
"}}}

let s:cw = {}
function! s:cw.cursor_hide() "{{{1
  let self._hl_cursor_cmd = s:highlight_preserve('Cursor')
  let self._t_ve_save = &t_ve

  highlight Cursor NONE
  let &t_ve=''
endfunction

function! s:cw.cursor_restore() "{{{1
  execute self._hl_cursor_cmd
  let &t_ve = self._t_ve_save
endfunction

function! s:cw.setup() "{{{1
  if !has_key(self, 'highlighter')
    let self.highlighter = choosewin#highlighter#new('ChooseWin')
  endif

  let self.color_label = self.highlighter.register(g:choosewin_color_label)
  let self.color_other = g:choosewin_label_fill
        \ ? self.color_label
        \ : self.highlighter.register(g:choosewin_color_other)
  let self.color_cursor = self.highlighter.register(g:choosewin_color_cursor)
endfunction

function! s:cw.statusline_update(active) "{{{1
  let g:choosewin_active = a:active
  let &ro = &ro

  if g:choosewin_statusline_replace
    if a:active
      call self.statusline_save()
      call self.statusline_replace()
    else
      call self.statusline_restore()
    endif
  endif

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
endfunction

function! s:cw.prepare_statusline(win, align) "{{{1
  let pad = repeat(' ', g:choosewin_label_padding)
  let win_s = pad . a:win . pad

  if a:align ==# 'left'
    return printf('%%#%s# %s %%#%s# %%= ', self.color_label, win_s, self.color_other)

  elseif a:align ==# 'right'
    return printf('%%#%s# %%= %%#%s# %s ', self.color_other, self.color_label, win_s)

  elseif a:align ==# 'center'
    let padding = repeat(' ', winwidth(a:win)/2-len(win_s))
    return printf('%%#%s# %s %%#%s# %s %%#%s# %%= ',
          \ self.color_other, padding, self.color_label, win_s, self.color_other)
  endif
endfunction

function! s:cw.show_prompt() "{{{1
  call s:echohl('PreProc')         | echon 'choose > '
  call s:echohl(self.color_cursor) | echon ' '
  call s:echohl('Normal')
endfunction

function! s:cw.start(...) "{{{1
  let self.wins = {}
  let self.winnums = range(1, winnr('$'))

  if g:choosewin_return_on_single_win && len(self.winnums) ==# 1
    return
  endif

  call self.setup()

  try
    call self.cursor_hide()
    call self.statusline_update(1)
    call self.show_prompt()

    let win = str2nr(nr2char(getchar()))
    if index(self.winnums, win) ==# -1
      return
    endif
    silent execute win . 'wincmd w'
  finally
    echo ''
    call self.statusline_update(0)
    call self.cursor_restore()
  endtry
endfunction

function! choosewin#start() "{{{1
  call s:cw.start()
endfunction

function! choosewin#color_set() "{{{1
  call s:cw.setup()
  call s:cw.highlighter.refresh()
endfunction

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

" call s:cw.setup()
" echo s:cw.color

" vim: foldmethod=marker
