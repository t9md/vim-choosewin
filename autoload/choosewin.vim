" Constant:
let s:NOT_FOUND       = -1
let s:TYPE_FUNCTION   = 2
let s:TYPE_DICTIONARY = 4

" Utility:
function! s:msg(msg) "{{{1
  if !empty(a:msg)
    echohl Type
    echon 'choosewin: '
    echohl Normal
  endif
  echon a:msg
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

function! s:str_split(str) "{{{1
  return split(a:str, '\zs')
endfunction
"}}}

" Main:
let s:cw = {}
function! s:cw.get_env() "{{{1
  return {
        \ 'win': { 'cur': winnr(),     'all': self.win_all() },
        \ 'tab': { 'cur': tabpagenr(), 'all': self.tab_all() },
        \ }
endfunction

function! s:cw.tab_all() "{{{1
  return range(1, tabpagenr('$'))
endfunction

function! s:cw.win_all() "{{{1
  return range(1, winnr('$'))
endfunction

function! s:cw.statusline_save(winnums) "{{{1
  for win in a:winnums
    let self.statusline[win] = getwinvar(win, '&statusline')
  endfor
endfunction

function! s:cw.blink_cword() "{{{1
  if ! self.conf['blink_on_land']
    return
  endif
  for i in range(2)
    let id = matchadd(self.color.Land, s:cword_pattern) | redraw | sleep 80m
    call matchdelete(id)                                | redraw | sleep 80m
  endfor
endfunction
let s:cword_pattern = '\k*\%#\k*'

function! s:cw.statusline_replace(winnums) "{{{1
  call self.statusline_save(a:winnums)

  for win in a:winnums
    let s = self.prepare_label(win, self.conf['label_align'])
    call setwinvar(win, '&statusline', s)
  endfor
endfunction

function! s:cw.statusline_restore() "{{{1
  for [win, val] in items(self.statusline)
    call setwinvar(win, '&statusline', val)
  endfor
endfunction

function! s:cw.prepare_label(win, align) "{{{1
  let pad   = repeat(' ', self.conf['label_padding'])
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
  let pad   = repeat(' ', self.conf['label_padding'])
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

function! s:cw.init() "{{{1
  let self.exception       = ''
  let self.statusline      = {}
  let self.tablabel        = self.conf['tablabel']
  let self._tablabel_split = s:str_split(self.tablabel)
  let self.tab_options         = {}
  let self.win_dest        = ''
  let self.env             = self.get_env()
  let self.env_orig        = deepcopy(self.env)
  let self.keymap          = filter(
        \ extend(self.keymap_default(), self.conf['keymap']),
        \ "v:val !=# '<NOP>'")

  if self.conf['overlay_enable']
    let self.overlay = choosewin#overlay#get()
  endif
  call self.tablabel_init(self.env.tab.all, self.tablabel)
endfunction

function! s:cw.keymap_default() "{{{1
  return {
        \ '0':     'tab_first',
        \ '[':     'tab_prev',
        \ ']':     'tab_next',
        \ '$':     'tab_last',
        \ ';':     'win_land',
        \ "\<CR>": 'win_land',
        \ }
endfunction

function! s:cw.prompt_show(prompt) "{{{1
  echohl PreProc  | echon a:prompt | echohl Normal
endfunction

function! s:cw.read_input() "{{{1
  redraw
  call self.prompt_show('choose > ')
  return nr2char(getchar())
endfunction

function! s:cw.config() "{{{1
  return {
        \ 'statusline_replace':        g:choosewin_statusline_replace,
        \ 'tabline_replace':           g:choosewin_tabline_replace,
        \ 'overlay_enable':            g:choosewin_overlay_enable,
        \ 'overlay_font_size':         g:choosewin_overlay_font_size,
        \ 'overlay_shade':             g:choosewin_overlay_shade,
        \ 'overlay_shade_priority':    g:choosewin_overlay_shade_priority,
        \ 'overlay_label_priority':    g:choosewin_overlay_label_priority,
        \ 'overlay_clear_multibyte':   g:choosewin_overlay_clear_multibyte,
        \ 'label_align':               g:choosewin_label_align,
        \ 'label_padding':             g:choosewin_label_padding,
        \ 'label_fill':                g:choosewin_label_fill,
        \ 'blink_on_land':             g:choosewin_blink_on_land,
        \ 'return_on_single_win':      g:choosewin_return_on_single_win,
        \ 'label':                     g:choosewin_label,
        \ 'keymap':                    g:choosewin_keymap,
        \ 'tablabel':                  g:choosewin_tablabel,
        \ 'hook':                      g:choosewin_hook,
        \ 'hook_enable':               g:choosewin_hook_enable,
        \ 'hook_bypass':               g:choosewin_hook_bypass,
        \ 'auto_choose':               0,
        \ 'noop':                      0,
        \ }
endfunction

function! s:cw.tab_choose(num) "{{{1
  silent execute 'tabnext ' a:num
  let self.env.tab.cur = a:num
endfunction

function! s:cw.win_choose(num, ...) "{{{1
  let self.env.win.cur = a:num
  let noop = get(a:000, 0)
  if noop
    return
  endif
  silent execute a:num 'wincmd w'
endfunction

function! s:cw.choose(winnum, winlabel) "{{{1
  let [action, num] = self.get_action(self.read_input())
  if action ==# 'tab'
    if num ==# self.env.tab.cur
      return
    endif
    call self.label_clear()
    call self.tab_choose(num)
    call self.label_show(self.win_all(), a:winlabel)
    return
  elseif action ==# 'win'
    let self.win_dest = num
    call self.label_clear()
    throw 'CHOOSED'
  elseif action ==# 'cancel'
    call self.label_clear()
    call self.tab_choose(self.env_orig.tab.cur)
    call self.win_choose(self.env_orig.win.cur)
    throw 'CANCELED'
  endif
endfunction

function! s:cw.get_action(input) "{{{1
  " [ kind, arg ] style
  for kind in [ 'tab', 'win']
    let num = s:get_ic(self['label2'. kind], a:input, s:NOT_FOUND)
    if num isnot s:NOT_FOUND
      return [ kind, num ]
    endif
  endfor

  let action = get(self.keymap, a:input)
  if !empty(action)
    if action =~# 'tab_'
      let tabn =
            \ action ==# 'tab_first' ? 1 :
            \ action ==# 'tab_prev'  ? max([1, self.env.tab.cur - 1]) :
            \ action ==# 'tab_next'  ? min([tabpagenr('$'), self.env.tab.cur + 1]) :
            \ action ==# 'tab_last'  ? tabpagenr('$') :
            \ s:NOT_FOUND

      if tabn is s:NOT_FOUND
        throw 'UNKNOWN_ACTION'
      endif

      return [ 'tab', tabn ]
    elseif action ==# 'win_land'
      return [ 'win', winnr() ]
    else
      throw 'UNKNOWN_ACTION'
    endif
  endif

  return [ 'cancel', 1 ]
endfunction

function! s:cw.land_win(winnum) "{{{1
  call self.win_choose(a:winnum, self.conf['noop'])
  call self.blink_cword()
endfunction
"}}}

let s:vim_tab_options = {
      \ '&tabline':     '%!choosewin#tabline()',
      \ '&guitablabel': '%{choosewin#get_tablabel(v:lnum)}',
      \ }

function! s:cw.last_status() "{{{1
  if !empty(self.exception)
    if self.exception =~# 'CANCELED\|RETURN'
      return []
    else
      return [ self.env.tab.cur, self.env.win.cur ]
    endif
  endif
endfunction

function! s:cw.valid_winnums(winnums) "{{{1
  return filter(copy(a:winnums), ' index(self.win_all(), v:val) != -1 ')
endfunction

function! s:cw.call_hook(hook_point, arg) "{{{1
  if !self.conf['hook_enable']
        \ || index(self.conf['hook_bypass'], a:hook_point ) !=# -1
    return a:arg
  endif
  let HOOK = get(self.conf['hook'], a:hook_point, 0)
  if type(HOOK) is s:TYPE_FUNCTION
    return call(HOOK, [a:arg], {})
  else
    return a:arg
  endif
endfunction

function! s:cw.label_show(winnums, winlabel) "{{{1
  try
    " don't copy(a:winnums) intentionally for performance
    let winnums = self.call_hook('filter_window', a:winnums)
  catch
    let winnums = a:winnums
  endtry
  let winnums = winnums[ : len(a:winlabel) - 1 ]

  call self.winlabel_init(winnums, a:winlabel)

  if self.conf['statusline_replace']
    call self.statusline_replace(winnums)
  endif
  if self.conf['overlay_enable']
    call self.overlay.render(winnums, self.conf)
  endif
  redraw
endfunction

function! s:cw.label_clear() "{{{1
  if self.conf['statusline_replace']
    call self.statusline_restore()
  endif
  if self.conf['overlay_enable']
    call self.overlay.restore()
  endif
endfunction

function! s:cw.tab_replace() "{{{1
  if !self.conf['tabline_replace']
    return
  endif
  let self.tab_options = s:options_replace(s:vim_tab_options)
endfunction

function! s:cw.tab_restore() "{{{1
  if !self.conf['tabline_replace']
    return
  endif
  call s:options_restore(self.tab_options)
endfunction

function! s:cw.first_path(winnums) "{{{1
  if empty(a:winnums)
    throw 'RETURN'
  endif
  if len(a:winnums) ==# 1
    if self.conf['auto_choose']
      let self.win_dest = a:winnums[0]
      throw 'CHOOSED'
    elseif self.conf['return_on_single_win']
      throw 'RETURN'
    endif
  endif
endfunction

function! s:cw.start(winnums, ...) "{{{1
  let self.conf  = extend(self.config(), get(a:000, 0, {}), 'force')
  let self.hlter = choosewin#highlighter#get()
  let self.color = self.hlter.color
  let winnums    = self.valid_winnums(a:winnums)

  try
    call self.state_update(1)
    call self.init()
    call self.first_path(winnums)

    call self.tab_replace()
    call self.label_show(winnums, self.conf['label'])
    while 1
      call self.choose(self.win_all(), self.conf['label'])
    endwhile
  catch
    let self.exception = v:exception
  finally
    call self.finish()
    call self.state_update(0)
    return self.last_status()
  endtry
endfunction

function! s:cw.state_update(state) "{{{1
  " for statusline plugin
  let g:choosewin_active = a:state
  " let &readonly = &readonly
  " redraw
endfunction

function! s:cw.message() "{{{1
  if self.exception =~# 'CHOOSED\|RETURN'
    return
  endif
  call s:msg(self.exception)
endfunction

function! s:cw.finish() "{{{1
  call self.tab_restore()
  echo '' | redraw
  if self.conf['noop'] && self.env.tab.cur !=# self.env_orig.tab.cur
    silent execute 'tabnext ' self.env_orig.tab.cur
  endif
  if !empty(self.win_dest)
    call self.land_win(self.win_dest)
  endif
  call self.message()
endfunction

function! choosewin#start(...) "{{{1
  return call(s:cw.start, a:000, s:cw)
endfunction

function! choosewin#tabline() "{{{1
  return s:cw.tabline()
endfunction

function! choosewin#config() "{{{1
  return s:cw.config()
endfunction

function! choosewin#get_tablabel(tabnum) "{{{1
  return s:cw.get_tablabel(a:tabnum)
endfunction
"}}}
" vim: foldmethod=marker
