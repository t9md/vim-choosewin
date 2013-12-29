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

function! s:dict_invert(dict) "{{{1
  let R = {}
  for [c, w] in items(copy(a:dict))
    let R[w] = c
  endfor
  return R
endfunction

function! s:echohl(hlname) "{{{1
  execute 'echohl' a:hlname
endfunction
"}}}

let s:cw = {}

function! s:cw.setup() "{{{1
  if !has_key(self, 'highlighter')
    let self.highlighter = choosewin#highlighter#new('ChooseWin')
  endif

  let self.color_label = self.highlighter.register(g:choosewin_color_label)
  let self.color_other = g:choosewin_label_fill
        \ ? self.color_label
        \ : self.highlighter.register(g:choosewin_color_other)
  let self.color_label_current =
        \ self.highlighter.register(g:choosewin_color_label_current)
endfunction

function! s:cw.statusline_update(active, winnums) "{{{1
  if g:choosewin_statusline_replace
    if a:active
      call self.statusline_save(a:winnums)
      call self.statusline_replace(a:winnums)
    else
      call self.statusline_restore(a:winnums)
    endif
  endif

  echo ''
  let g:choosewin_active = a:active
  let &ro = &ro
  redraw
endfunction

function! s:cw.statusline_save(winnums) "{{{1
  for win in a:winnums
    let self.options[win] = getwinvar(win, '&statusline')
  endfor
endfunction

function! s:cw.statusline_restore(winnums) "{{{1
  for win in a:winnums
    call setwinvar(win, '&statusline', self.options[win])
  endfor
endfunction

function! s:cw.statusline_replace(winnums) "{{{1
  " call s:plog(self.win2label)
  for win in a:winnums
    let s = self.prepare_label(win, g:choosewin_label_align)
    call setwinvar(win, '&statusline', s)
  endfor
endfunction

function! s:cw.tabline_save() "{{{1
  let self.options['&tabline']     = &tabline
  let self.options['&guitablabel'] = &guitablabel
endfunction

function! s:cw.tabline_restore() "{{{1
  let &tabline     = self.options['&tabline']
  let &guitablabel = self.options['&guitablabel']
endfunction

function! s:cw.tabline_replace() "{{{1
  let &tabline = '%!choosewin#tabline()'
endfunction

function! s:cw.prepare_label(win, align) "{{{1
  let pad = repeat(' ', g:choosewin_label_padding)
  " call s:plog(a:win)
  let label = self.win2label[a:win]
  let win_s = pad . label . pad
  let color = winnr() ==# a:win
        \ ? self.color_label_current
        \ : self.color_label

  if a:align ==# 'left'
    return printf('%%#%s# %s %%#%s# %%= ', color, win_s, self.color_other)

  elseif a:align ==# 'right'
    return printf('%%#%s# %%= %%#%s# %s ', self.color_other, color, win_s)

  elseif a:align ==# 'center'
    let padding = repeat(' ', winwidth(a:win)/2-len(win_s))
    return printf('%%#%s# %s %%#%s# %s %%#%s# %%= ',
          \ self.color_other, padding, color, win_s, self.color_other)
  endif
endfunction

function! s:cw.tabline() "{{{1
  let pad   = repeat(' ', g:choosewin_label_padding)
  let R = ''
  let tabnums = range(1, tabpagenr('$'))
  let lasttab = tabnums[-1]
  let sep = printf('%%#%s# ', self.color_other)
  for tn in tabnums
    let label = self.tab2label[tn]
    let s     = pad . label . pad
    let color = tabpagenr() ==# tn
          \ ? self.color_label_current
          \ : self.color_label
    let R .= printf('%%#%s# %s ', color, s)
    let R .= tn !=# lasttab ? sep : ''
  endfor
  let R .= printf('%%#%s#', self.color_other)
  return R
endfunction

function! s:cw.label2num(nums, label) "{{{1
  let R = {}
  let nums = copy(a:nums)
  for c in split(a:label, '\zs')
    let n = remove(nums, 0)
    let R[c] = n
    if empty(nums)
      break
    endif
  endfor
  return R
endfunction

function! s:cw.get(table, char) "{{{1
  return get(a:table, a:char, 
        \  get(a:table, tolower(a:char),  
        \    get(a:table, toupper(a:char), -1))) 
endfunction

function! s:cw.winlabel_init(label)
  let self.label2win  = self.label2num(self.winnums, a:label)
  let self.win2label  = s:dict_invert(self.label2win)
endfunction

function! s:cw.start(winnums, ...) "{{{1
  if g:choosewin_return_on_single_win && len(a:winnums) ==# 1
    return
  endif
  let winlabel    = !empty(a:0) ? a:1 : g:choosewin_label

  let self.options    = {}
  let self.win_dest   = ''
  let self.winnums    = a:winnums
  let self.tabnums    = range(1, tabpagenr('$'))

  call self.winlabel_init(winlabel)

  let tablabel = g:choosewin_tablabel
  let self.label2tab  = self.label2num(self.tabnums, tablabel)
  let self.tab2label  = s:dict_invert(self.label2tab)

  call self.setup()
  try
    call self.statusline_update(1, self.winnums)
    call self.tabline_save()
    let &tabline     = '%!choosewin#tabline()'
    let &guitablabel = '%{g:choosewin_tablabel[v:lnum-1]}'

    while 1
      redraw
      echohl PreProc  | echon 'choose > ' | echohl Normal

      let input = nr2char(getchar())
      let tabn = self.get(self.label2tab, input)

      if tabn != -1
        if tabn ==# tabpagenr()
          continue
        endif
        call self.statusline_update(0, self.winnums)
        silent execute 'tabnext ' tabn

        let self.winnums  = range(1, winnr('$'))
        call self.winlabel_init(winlabel)
        call self.statusline_update(1, self.winnums)
      else
        let winn = self.get(self.label2win, input)
        if winn !=# -1
          let self.win_dest = winn
        endif
        break
      endif
    endwhile
  finally
    call self.statusline_update(0, self.winnums)
    call self.tabline_restore()
    if !empty(self.win_dest)
      silent execute self.win_dest 'wincmd w'
    endif
  endtry
endfunction

" function! s:cw.start(winnums, ...) "{{{1
  " if g:choosewin_return_on_single_win && len(a:winnums) ==# 1
    " return
  " endif
  " let label = !empty(a:0) ? a:1 : g:choosewin_label

  " let self.options    = {}
  " let self.win_dest   = ''
  " let self.winnums    = a:winnums
  " let self.label2win  = self.label2num(a:winnums, label)
  " let self.win2label  = s:dict_invert(self.label2win)

  " call self.setup()
  " try
    " call self.statusline_update(1)
    " echohl PreProc  | echon 'choose-win > ' | echohl Normal
    " " redraw

    " let dest = self.get(self.label2win, nr2char(getchar()))
    " if dest ==# -1
      " return
    " endif
    " let self.win_dest = dest
  " finally
    " call self.statusline_update(0)
    " if !empty(self.win_dest)
      " silent execute self.win_dest 'wincmd w'
    " endif
  " endtry
" endfunction

function! choosewin#start(...) "{{{1
  call call(s:cw.start, a:000, s:cw)
endfunction

function! choosewin#color_set() "{{{1
  call s:cw.setup()
  call s:cw.highlighter.refresh()
endfunction

function! choosewin#tabline() "{{{1
  return s:cw.tabline()
endfunction

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

" call s:cw.setup()
" echo s:cw.color

" vim: foldmethod=marker
