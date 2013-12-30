
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
  " let screen = has("gui_running") ? 'gui' : 'cterm'
  " let color_label_tab_orig = copy(g:choosewin_color_label_current)
  " let color_label_tab_orig[screen] = color_label_tab_orig[screen][0:1] + ['underline']
  " let self.color_label_tab_orig = 
        " \ self.highlighter.register(color_label_tab_orig)
  let self.color_land =
        \ self.highlighter.register(g:choosewin_color_land)
endfunction

function! s:cw.statusline_save(winnums) "{{{1
  for win in a:winnums
    let self.statusline[win] = getwinvar(win, '&statusline')
  endfor
endfunction

function! s:cw.blink_cword() "{{{1
  if !g:choosewin_blink_on_land
    return
  endif
  let pat = '\k*\%#\k*' 
  for i in range(2)
    let id = matchadd(self.color_land, pat) | redraw | sleep 80m
    call matchdelete(id)                    | redraw | sleep 80m
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
  let label = split(copy(a:label), '\zs')

  while 1
    let R[remove(label, 0)] = remove(nums, 0)
    if empty(nums) || empty(label)
      break
    endif
  endwhile

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
  " let self.env = { 'win': winnr(), 'tab': tabpagenr() }
  let self.statusline = {}
  let self.options    = {}
  let self.win_dest = ''
  call self.tablabel_init(range(1, tabpagenr('$')), g:choosewin_tablabel)
endfunction

function! s:cw.prompt_show(prompt) "{{{1
  echohl PreProc  | echon a:prompt | echohl Normal
endfunction

function! s:cw.read_input() "{{{1
  call self.prompt_show('choose > ')
  return nr2char(getchar())
endfunction

function! s:cw.land_win(winnum) "{{{1
  silent execute a:winnum 'wincmd w'
  call self.blink_cword()
endfunction
"}}}

let s:vim_options = {
      \ '&tabline':     '%!choosewin#tabline()',
      \ '&guitablabel': '%{g:choosewin_tablabel[v:lnum-1]}',
      \ }

function! s:cw.env()
  return [ tabpagenr(), winnr() ]
endfunction

function! s:cw.start(winnums, ...) "{{{1

  if g:choosewin_return_on_single_win && len(a:winnums) ==# 1
    return []
  endif
  call self.hl_set()
  if get(a:000, 0, 0) && len(a:winnums) ==# 1
    call self.land_win(a:winnums[0])
    return self.env()
  endif

  try
    let NOT_FOUND = -1
    let winlabel = get(a:000, 1, g:choosewin_label)
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
        else
          return []
        endif
        break
      endif
    endwhile
  finally
    call self.statusline_restore()
    call s:options_restore(self.options)
    echo '' | redraw
    if !empty(self.win_dest)
      call self.land_win(self.win_dest)
    endif
  endtry
  return self.env()
endfunction

function! choosewin#start(...) "{{{1
  return call(s:cw.start, a:000, s:cw)
endfunction

function! choosewin#color_set() "{{{1
  call s:cw.hl_set()
  call s:cw.highlighter.refresh()
endfunction

function! choosewin#tabline() "{{{1
  return s:cw.tabline()
endfunction
"}}}

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

" call s:cw.setup()
" echo s:cw.color

" vim: foldmethod=marker
