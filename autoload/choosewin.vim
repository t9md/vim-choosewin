" Constant:
if expand("%:p") ==# expand("<sfile>:p")
  unlet! s:NOT_FOUND
endif
let s:NOT_FOUND = -1
lockvar s:NOT_FOUND

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

function! s:str_split(str) "{{{1
  return split(a:str, '\zs')
endfunction

function! s:get_env() "{{{1
  return {
        \ 'win': { 'cur': winnr(),    'all': range(1, winnr('$'))     },
        \ 'tab': { 'cur': tabpagenr(), 'all': range(1, tabpagenr('$')) },
        \ }
endfunction

function! s:goto_tabwin(tabnum, winnum) "{{{1
  silent execute 'tabnext ' a:tabnum
  silent execute a:winnum 'wincmd w'
endfunction
"}}}

let s:cw = {}
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
    let id = matchadd(self.color.Land, pat) | redraw | sleep 80m
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
        \ ? self.color.LabelCurrent
        \ : self.color.Label

  if a:align ==# 'left'
    return printf('%%#%s# %s %%#%s# %%= ', color, win_s, self.color.Other)

  elseif a:align ==# 'right'
    return printf('%%#%s# %%= %%#%s# %s ', self.color.Other, color, win_s)

  elseif a:align ==# 'center'
    let padding = repeat(' ', winwidth(a:win)/2-len(win_s))
    return printf('%%#%s# %s %%#%s# %s %%#%s# %%= ',
          \ self.color.Other, padding, color, win_s, self.color.Other)
  endif
endfunction

function! s:cw.tabline() "{{{1
  let R         = ''
  let pad   = repeat(' ', g:choosewin_label_padding)
  let sepalator = printf('%%#%s# ', self.color.Other)
  for tabnum in self.env.tab.all
    let color = tabpagenr() ==# tabnum
          \ ? self.color.LabelCurrent
          \ : self.color.Label

    let R .= printf('%%#%s# %s ', color,  pad . self.get_tablabel(tabnum) . pad)
    let R .= tabnum !=# self.env.tab.all[-1] ? sepalator : ''
  endfor
  let R .= printf('%%#%s#', self.color.Other)
  return R
endfunction

function! s:cw.get_tablabel(tabnum)
  return get(self._tablabel_split, a:tabnum - 1, '..')
endfunction

function! s:cw.label2num(nums, label) "{{{1
  let R = {}
  if empty(a:label)
    return R
  endif
  let nums = copy(a:nums)
  let label = s:str_split(a:label)
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

function! s:cw.keymap_for_tab(tabs, chars)
  let chars   = s:str_split(a:chars)
  let actions = [ 'first', 'prev', 'next', 'last' ]
  let R = {}
  for action in actions
    let R[remove(chars, 0)] = action
  endfor
  return R
endfunction

function! s:cw.init() "{{{1
  let self.statusline      = {}
  let self.tablabel        = g:choosewin_tablabel[:-5]
  let self._tablabel_split = s:str_split(self.tablabel)
  let tab_sepecial_chars   = g:choosewin_tablabel[-4:]
  let self.options         = {}
  let self.win_dest        = ''
  let self.env      = s:get_env()
  let self.env_orig = deepcopy(self.env)
  let self.keymap_tab =
        \ self.keymap_for_tab(self.env.tab.all, tab_sepecial_chars)
  call self.tablabel_init(self.env.tab.all, self.tablabel)
endfunction

function! s:cw.prompt_show(prompt) "{{{1
  echohl PreProc  | echon a:prompt | echohl Normal
endfunction

function! s:cw.read_input() "{{{1
  call self.prompt_show('choose > ')
  return nr2char(getchar())
endfunction

function! s:cw.get_tabnum(input)
  let tabnum = s:get_ic(self.label2tab, a:input, s:NOT_FOUND)

  if tabnum !=# s:NOT_FOUND
    return tabnum
  endif

  let action = s:get_ic(self.keymap_tab, a:input, s:NOT_FOUND)
  if action != s:NOT_FOUND
    return self.action2tabnum(action)
  endif

  return s:NOT_FOUND
endfunction

function! s:cw.action2tabnum(action) "{{{1
  if     a:action ==# 'first'
    return 1
  elseif a:action ==# 'prev'
    return max([1, self.env.tab.cur - 1])
  elseif a:action ==# 'next'
    return min([tabpagenr('$'), self.env.tab.cur + 1])
  elseif a:action ==# 'last'
    return tabpagenr('$')
  endif
endfunction

function! s:cw.tab_change(input) "{{{1
endfunction


function! s:cw.land_win(winnum) "{{{1
  silent execute a:winnum 'wincmd w'
  call self.blink_cword()
endfunction
"}}}

let s:vim_tab_options = {
      \ '&tabline':     '%!choosewin#tabline()',
      \ '&guitablabel': '%{choosewin#get_tablabel(v:lnum)}',
      \ }

function! s:cw.status()
  return [ tabpagenr(), winnr() ]
endfunction

function! s:cw.screen_refresh(winnums, winlabel)
  call self.winlabel_init(a:winnums, a:winlabel)
  if g:choosewin_statusline_replace
    call self.statusline_replace(a:winnums)
  endif
  if g:choosewin_overlay_enable
    call self.overlay.overlay(a:winnums)
  endif
  redraw
endfunction

function! s:cw.start(winnums, ...) "{{{1
  let self.overlay = choosewin#overlay#get()
  let self.hlter   = choosewin#highlighter#get()
  let self.color   = self.hlter.color
  if len(a:winnums) ==# 1
    if get(a:000, 0, 0)
      call self.land_win(a:winnums[0])
      return self.status()
    elseif g:choosewin_return_on_single_win
      return []
    endif
  endif

  try
    let winlabel = get(a:000, 1, g:choosewin_label)
    let winnums  = a:winnums
    call self.init()

    if g:choosewin_tabline_replace
      let self.options = s:options_replace(s:vim_tab_options)
    endif

    call self.screen_refresh(winnums, winlabel)

    while 1
      let input = self.read_input()
      let tabnnum = self.get_tabnum(input)
      if tabnnum !=# s:NOT_FOUND
        if tabnnum ==# tabpagenr()
          redraw
          continue
        endif
        call self.statusline_restore()
        if g:choosewin_overlay_enable
          call self.overlay.restore()
        endif
        silent execute 'tabnext ' tabnnum
        let self.env.tab.cur = tabpagenr()
        let winnums  = range(1, winnr('$'))
        call self.screen_refresh(winnums, winlabel)
      else
        let winn = s:get_ic(self.label2win, input, s:NOT_FOUND)
        if winn !=# s:NOT_FOUND
          let self.win_dest = winn
        elseif input ==# g:choosewin_land_char
          break
        else
          call s:goto_tabwin(self.env_orig.tab.cur, self.env_orig.win.cur)
          return []
        endif
        break
      endif
    endwhile
  finally
    call self.statusline_restore()
    if g:choosewin_overlay_enable
      call self.overlay.restore()
    endif
    call s:options_restore(self.options)
    echo '' | redraw
    if !empty(self.win_dest)
      call self.land_win(self.win_dest)
    endif
  endtry
  return self.status()
endfunction

function! choosewin#start(...) "{{{1
  return call(s:cw.start, a:000, s:cw)
endfunction


function! choosewin#tabline() "{{{1
  return s:cw.tabline()
endfunction

function! choosewin#get_tablabel(tabnum) "{{{1
  return s:cw.get_tablabel(a:tabnum)
endfunction
"}}}

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

" call s:cw.setup()
" echo s:cw.color

" vim: foldmethod=marker
















































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































