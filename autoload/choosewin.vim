" Vars:
let s:NOT_FOUND       = -1
let s:vim_tab_options = {
      \ '&tabline':     '%!choosewin#tabline()',
      \ '&guitablabel': '%{choosewin#get_tablabel(v:lnum)}',
      \ }

" Util::
let s:_ = choosewin#util#get()

" Main:
let s:cw = {}
function! s:cw.start(winnums, ...) "{{{1
  let conf       = get(a:000, 0, {})
  let self.conf  = extend(choosewin#config#get(), conf)
  let self.color = choosewin#color#get()

  " Elminate non-exsiting window.
  let winnums = 
        \ filter(a:winnums, 'index(self.win_all(), v:val) != -1')
  try
    call self.state_update(1)
    call self.setup()
    call self.first_path(winnums)
    call self.setup_tab()

    call self.label_show(winnums, self.conf['label'])
    while 1
      call self.choose(self.win_all(), self.conf['label'])
    endwhile
  catch
    let self.exception = v:exception
  finally
    call self.restore()
    call self.finish()
    call self.state_update(0)
    return self.last_status()
  endtry
endfunction

function! s:cw.setup() "{{{1
  let self.exception   = ''
  let self.win_dest    = ''
  let self.statusline  = {}
  let self.tab_options = {}
  let self.env         = {
        \ 'win': { 'cur': winnr(),     'all': self.win_all() },
        \ 'tab': { 'cur': tabpagenr(), 'all': range(1, tabpagenr('$'))},
        \ 'buf': { 'cur': bufnr('') },
        \ }
  let self.env_orig  = deepcopy(self.env)
  let self.label2tab = s:_.dict_create(self.conf['tablabel'], self.env.tab.all)
  let self.tab2label = s:_.dict_create(self.env.tab.all, self.conf['tablabel'])

  if !has_key(self, 'previous')
    let self.previous = []
  endif

  if self.conf['overlay_enable']
    let self.overlay = choosewin#overlay#get()
  endif
endfunction

function! s:cw.setup_tab() "{{{1
  if !self.conf['tabline_replace']
    return
  endif
  let self.tab_options = s:_.buffer_options_set(bufnr(''), s:vim_tab_options)
endfunction


function! s:cw.statusline_replace(winnums) "{{{1
  for win in a:winnums
    let self.statusline[win] = getwinvar(win, '&statusline')
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

function! s:cw.tab_choose(num) "{{{1
  silent execute 'tabnext ' a:num
  let self.env.tab.cur = a:num
endfunction

function! s:cw.win_choose(num, ...) "{{{1
  let noop = get(a:000, 0)
  if ! noop
    silent execute a:num 'wincmd w'
  endif
  let self.env.win.cur = a:num
endfunction

let g:choosewin_debug = 1
function! s:cw.choose(winnum, winlabel) "{{{1
  let [action, num] = self.get_action(self.read_input())
  call self.label_clear()

  while 1
    if action ==# 'tab'
      call self.tab_choose(num)
      call self.label_show(self.win_all(), a:winlabel)
      return
    elseif action ==# 'win'
      let self.win_dest = num
      throw 'CHOSE'
    elseif action ==# 'previous'
      if empty(self.previous)
        throw 'NO_PREVIOUS_WINDOW'
      endif
      let [ tab_dst, self.win_dest ] = self.previous
      call self.tab_choose(tab_dst)
      throw 'CHOSE'
    elseif action =~# '^swap'
      if !self.conf['swap']
        let self.conf['swap'] = 1

        if !has_key(self.conf, 'swap_stay')
          let self.conf['swap_stay'] = action ==# 'swap_stay'
        endif

        call self.label_show(self.win_all(), a:winlabel)
        return
      else
        let action = 'previous'
        continue
      endif
    elseif action ==# 'cancel'
      call self.tab_choose(self.env_orig.tab.cur)
      call self.win_choose(self.env_orig.win.cur)
      throw 'CANCELED'
    endif
  endwhile
endfunction

function! s:cw.get_action(input) "{{{1
  " [ kind, arg ] style
  for kind in [ 'tab', 'win']
    let num = s:_.get_ic(self['label2'. kind], a:input, s:NOT_FOUND)
    if num isnot s:NOT_FOUND
      return [ kind, num ]
    endif
  endfor

  let action = get(self.conf['keymap'], a:input)
  if !empty(action)
    if action =~# '^tab_'
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
    elseif action ==# 'previous'
      return [ 'previous', -1]
    elseif action =~# '^swap'
      return [ action, -1]
    else
      throw 'UNKNOWN_ACTION'
    endif
  endif

  return [ 'cancel', 1 ]
endfunction
"}}}

function! s:cw.call_hook(hook_point, arg) "{{{1
  if !self.conf['hook_enable']
        \ || index(self.conf['hook_bypass'], a:hook_point ) !=# -1
    return a:arg
  endif
  let HOOK = get(self.conf['hook'], a:hook_point, 0)
  if s:_.is_Funcref(HOOK)
    return call(HOOK, [a:arg])
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

  let self.label2win = s:_.dict_create(a:winlabel, winnums)
  let self.win2label = s:_.dict_create(winnums, a:winlabel)

  if self.conf['statusline_replace']
    call self.statusline_replace(winnums)
  endif
  if self.conf['overlay_enable']
    call self.overlay.start(winnums, self.conf)
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

function! s:cw.first_path(winnums) "{{{1
  if empty(a:winnums)
    throw 'RETURN'
  endif
  if len(a:winnums) ==# 1
    if self.conf['auto_choose']
      let self.win_dest = a:winnums[0]
      throw 'CHOSE'
    elseif self.conf['return_on_single_win']
      throw 'RETURN'
    endif
  endif
endfunction
"}}}

" Tabline:
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

function! s:cw.get_tablabel(num) "{{{1
  return get(s:_.str_split(self.conf['tablabel']), a:num - 1, '..')
endfunction
"}}}

" Misc:
function! s:cw.read_input() "{{{1
  redraw
  let prompt = ( self.conf['swap'] ? '[swap] ' : '' ) . 'chooose > '
  echohl PreProc
  echon prompt
  echohl Normal
  return nr2char(getchar())
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

function! s:cw.win_all() "{{{1
  return range(1, winnr('$'))
endfunction
function! s:cw.last_status() "{{{1
  if !empty(self.exception)
    if self.exception =~# 'CANCELED\|RETURN'
      return []
    else
      return [ self.env.tab.cur, self.env.win.cur ]
    endif
  endif
endfunction

function! s:cw.state_update(state) "{{{1
  " for statusline plugin
  let g:choosewin_active = a:state
  " let &readonly = &readonly
  " redraw
endfunction

function! s:cw.message() "{{{1
  if self.exception =~# 'CHOSE\|RETURN'
    return
  endif
  if !empty(self.exception)
    echohl Type
    echon 'choosewin: '
    echohl Normal
  endif
  echon self.exception
endfunction
"}}}

" Restore:
function! s:cw.restore() "{{{1
  call self.tab_restore()
endfunction

function! s:cw.tab_restore() "{{{1
  if !self.conf['tabline_replace']
    return
  endif
  call s:_.buffer_options_set(bufnr(''), self.tab_options)
endfunction

function! s:cw.finish() "{{{1
  echo '' | redraw
  if self.conf['noop'] && self.env.tab.cur !=# self.env_orig.tab.cur
    silent execute 'tabnext ' self.env_orig.tab.cur
  endif
  if !empty(self.win_dest)
    call self.win_choose(self.win_dest, self.conf['noop'])

    if self.conf['noop']
      return
    endif

    if self.conf['swap']
      let buf_dst = winbufnr('')
      execute 'hide buffer' self.env_orig.buf.cur
      silent execute 'tabnext ' self.env_orig.tab.cur
      silent execute self.env_orig.win.cur 'wincmd w'
      execute 'hide buffer' buf_dst

      if self.conf['swap_stay']
        let self.previous = [ self.env.tab.cur, self.env.win.cur ]
      else
        silent execute 'tabnext ' self.env.tab.cur
        silent execute self.env.win.cur 'wincmd w'
        let self.previous = [ self.env_orig.tab.cur, self.env_orig.win.cur ]
      endif
    else
      let self.previous = [ self.env_orig.tab.cur, self.env_orig.win.cur ]
    endif
  endif
  call self.blink_cword()
  call self.message()
endfunction
"}}}

" API:
function! choosewin#start(...) "{{{1
  return call(s:cw.start, a:000, s:cw)
endfunction

function! choosewin#tabline() "{{{1
  return s:cw.tabline()
endfunction

function! choosewin#config() "{{{1
  return s:cw.config()
endfunction

function! choosewin#get_tablabel(num) "{{{1
  return s:cw.get_tablabel(a:num)
endfunction

function! choosewin#get_previous() "{{{1
  return s:cw.previous
endfunction
"}}}

" vim: foldmethod=marker
