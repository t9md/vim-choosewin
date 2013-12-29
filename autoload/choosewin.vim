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
let s:cw.prompt = 'choose > '

function! s:cw.setup() "{{{1
  if !has_key(self, 'highlighter')
    let self.highlighter = choosewin#highlighter#new('ChooseWin')
  endif

  let self.color_label = self.highlighter.register(g:choosewin_color_label)
  let self.color_other = g:choosewin_label_fill
        \ ? self.color_label
        \ : self.highlighter.register(g:choosewin_color_other)
  " let self.color_cursor = self.highlighter.register(g:choosewin_color_cursor)
endfunction

function! s:cw.statusline_update(active) "{{{1
  if g:choosewin_statusline_replace
    if a:active
      call self.statusline_save()
      call self.statusline_replace()
    else
      call self.statusline_restore()
    endif
  endif

  echo ''
  let g:choosewin_active = a:active
  let &ro = &ro
  redraw
endfunction

function! s:cw.statusline_save() "{{{1
  for win in self.winnums
    let self.options[win] = getwinvar(win, '&statusline')
  endfor
endfunction

function! s:cw.statusline_restore() "{{{1
  for win in self.winnums
    call setwinvar(win, '&statusline', self.options[win])
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
  let label = self.w2c[a:win]
  let win_s = pad . label . pad

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

function! s:cw.winmap_create(winnums, label) "{{{1
  let winnums = copy(a:winnums)
  let R = {}
  for c in split(a:label, '\zs')
    let R[c] = remove(winnums, 0)
    if empty(winnums)
      break
    endif
  endfor
  return R
endfunction

function! s:cw.c2w_create(winnums, label) "{{{1
  let winnums = copy(a:winnums)
  let R = {}
  for c in split(a:label, '\zs')
    let wn = remove(winnums, 0)
    let R[c] = wn
    if empty(winnums)
      break
    endif
  endfor
  return R
endfunction

function! s:cw.w2c_create(c2w)
  let R = {}
  for [c, w] in items(copy(a:c2w))
    let R[w] = c
  endfor
  return R
endfunction

function! s:cw.get_win(char)
  return get(self.c2w, a:char, 
        \  get(self.c2w, tolower(a:char),  
        \    get(self.c2w, toupper(a:char), -1))) 
endfunction

function! s:cw.start(winnums, ...) "{{{1
  if g:choosewin_return_on_single_win && len(a:winnums) ==# 1
    return
  endif
  let label = !empty(a:0) ? a:1 : g:choosewin_label

  let self.options    = {}
  let self.win_dest   = ''
  let self.winnums    = a:winnums
  let self.c2w        = self.c2w_create(a:winnums, label)
  let self.w2c        = self.w2c_create(self.c2w)

  call self.setup()
  try
    call self.statusline_update(1)
    echohl PreProc  | echon self.prompt | echohl Normal

    let dest = self.get_win(nr2char(getchar()))
    if dest ==# -1
      return
    endif
    let self.win_dest = dest
  finally
    call self.statusline_update(0)
    if !empty(self.win_dest)
      silent execute self.win_dest 'wincmd w'
    endif
  endtry
endfunction

function! choosewin#start(...) "{{{1
  call call(s:cw.start, a:000, s:cw)
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
