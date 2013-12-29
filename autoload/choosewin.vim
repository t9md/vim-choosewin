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

function! s:get_ic(table, char, default) "{{{1
  " get ignore case
  let R = ''
  for char in [ a:char, tolower(a:char), toupper(a:char) ]
    let R = get(a:table, char, a:default)
    if R != a:default
      return R
    endif
  endfor
  return R
endfunction

function! s:options_replace(options) "{{{1
  let R = {}
  let curbuf = bufnr('')
  for [var, val] in items(a:options)
    let R[var] = getbufvar(curbuf, var)
    call setbufvar(curbuf, var, val)
    unlet var val
  endfor
  return R
endfunction

function! s:options_restore(options) "{{{1
  for [var, val] in items(a:options)
    call setbufvar(bufnr(''), var, val)
    unlet var val
  endfor
endfunction
"}}}

let s:cw = {}
function! s:cw.hl_set() "{{{1
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

function! s:cw.statusline_save(winnums) "{{{1
  for win in a:winnums
    let self.statusline[win] = getwinvar(win, '&statusline')
  endfor
endfunction

function! s:cw.statusline_replace(winnums) "{{{1
  call self.statusline_save(a:winnums)

  for win in a:winnums
    let s = self.prepare_label(win, g:choosewin_label_align)
    call setwinvar(win, '&statusline', s)
  endfor
endfunction

function! s:cw.statusline_restore() "{{{1
  for [win, val] in items(self.statusline)
    call setwinvar(win, '&statusline', val)
  endfor
endfunction


function! s:cw.prepare_label(win, align) "{{{1
  let pad = repeat(' ', g:choosewin_label_padding)
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
  let R         = ''
  let padding   = repeat(' ', g:choosewin_label_padding)
  let tabnums   = range(1, tabpagenr('$'))
  let lasttab   = tabnums[-1]
  let sepalator = printf('%%#%s# ', self.color_other)
  for tn in tabnums
    let label = self.tab2label[tn]
    let s     = padding . label . padding
    let color = tabpagenr() ==# tn
          \ ? self.color_label_current
          \ : self.color_label
    let R .= printf('%%#%s# %s ', color, s)
    let R .= tn !=# lasttab ? sepalator : ''
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


function! s:cw.winlabel_init(winnums, label) "{{{1
  let self.label2win  = self.label2num(a:winnums, a:label)
  let self.win2label  = s:dict_invert(self.label2win)
endfunction

function! s:cw.tablabel_init(tabnums, label) "{{{1
  let self.label2tab  = self.label2num(a:tabnums, a:label)
  let self.tab2label  = s:dict_invert(self.label2tab)
endfunction

function! s:cw.init() "{{{1
  let self.statusline = {}
  let self.options    = {}
  let self.win_dest = ''
  call self.tablabel_init(range(1, tabpagenr('$')), g:choosewin_tablabel)
  call self.hl_set()
endfunction

function! s:cw.prompt_show(prompt) "{{{1
  echohl PreProc  | echon a:prompt | echohl Normal
endfunction

function! s:cw.read_input() "{{{1
  call self.prompt_show('choose > ')
  return nr2char(getchar())
endfunction
"}}}

let s:vim_options = {
      \ '&tabline':     '%!choosewin#tabline()',
      \ '&guitablabel': '%{g:choosewin_tablabel[v:lnum-1]}',
      \ }

function! s:cw.start(winnums, ...) "{{{1
  if g:choosewin_return_on_single_win && len(a:winnums) ==# 1 | return | endif
  try
    let NOT_FOUND = -1
    let winlabel = !empty(a:0) ? a:1 : g:choosewin_label
    let winnums  = a:winnums
    call self.init()
    let self.options = s:options_replace(s:vim_options)

    while 1
      call self.winlabel_init(winnums, winlabel)
      call self.statusline_replace(winnums)
      redraw
      let input = self.read_input()
      let tabn = s:get_ic(self.label2tab, input, NOT_FOUND)
      if tabn !=# NOT_FOUND
        if tabn ==# tabpagenr()
          continue
        endif
        call self.statusline_restore()
        silent execute 'tabnext ' tabn
        let winnums  = range(1, winnr('$'))
      else
        let winn = s:get_ic(self.label2win, input, NOT_FOUND)
        if winn !=# NOT_FOUND
          let self.win_dest = winn
        endif
        break
      endif
    endwhile
  finally
    call self.statusline_restore()
    call s:options_restore(self.options)
    echo '' | redraw
    if !empty(self.win_dest)
      silent execute self.win_dest 'wincmd w'
    endif
  endtry
endfunction

function! choosewin#start(...) "{{{1
  call call(s:cw.start, a:000, s:cw)
endfunction

function! choosewin#color_set() "{{{1
  call s:cw.hl_set()
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
