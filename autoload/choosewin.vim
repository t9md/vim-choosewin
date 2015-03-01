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
function! s:cw.start(wins, ...) "{{{1
  let conf       = get(a:000, 0, {})
  let self.conf  = extend(choosewin#config#get(), conf)
  let self.color = choosewin#color#get()

  " Elminate non-exsiting window.
  let self.wins = filter(a:wins, 'index(self.win_all(), v:val) != -1')

  try
    call self.state_update(1)
    call self.setup()
    call self.first_path()
    if self.conf['tabline_replace']
      call self.setup_tab()
    endif

    call self.label_show()
    call self.choose()
  catch
    let self.exception = v:exception
  finally
    call self.restore()
    call self.finish()
    call self.state_update(0)
    return self.status()
  endtry
endfunction

function! s:cw.setup() "{{{1
  let self.exception   = ''
  let self.win_dest    = ''
  let self.win_option  = {}
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
  let self.tab_options = s:_.buffer_options_set(bufnr(''), s:vim_tab_options)
endfunction

function! s:cw.statusline_replace() "{{{1
  for winnr in self.wins
    let wv = {}
    let wv.options = s:_.window_options_set( winnr,
          \ { '&statusline': self.prepare_label(winnr, self.conf['label_align']) })
    call setwinvar(winnr, 'choosewin', wv)
  endfor
endfunction

function! s:cw.statusline_restore() "{{{1
  for winnr in self.wins
    let wv = remove(getwinvar(winnr, ''), 'choosewin')
    call s:_.window_options_set(winnr, wv.options)
  endfor
endfunction

function! s:cw.prepare_label(win, align) "{{{1
  let pad   = repeat(' ', self.conf['label_padding'])
  let label = self.win2label[a:win]
  let win_s = pad . label . pad
  let color = winnr() ==# a:win
        \ ? self.color.LabelCurrent
        \ : self.color.Label

  if a:align is 'left'
    return printf('%%#%s# %s %%#%s# %%= ', color, win_s, self.color.Other)
  endif

  if a:align is 'right'
    return printf('%%#%s# %%= %%#%s# %s ', self.color.Other, color, win_s)
  endif

  if a:align is 'center'
    let padding = repeat(' ', winwidth(a:win)/2-len(win_s))
    return printf('%%#%s# %s %%#%s# %s %%#%s# %%= ',
          \ self.color.Other, padding, color, win_s, self.color.Other)
  endif
endfunction

function! s:cw.tab_choose(num) "{{{1
  silent execute 'tabnext ' a:num
  let self.env.tab.cur = a:num
endfunction

function! s:cw.win_choose(num) "{{{1
  if !self.conf['noop']
    silent execute a:num 'wincmd w'
  endif
  let self.env.win.cur = a:num
endfunction

function! s:cw.choose() "{{{1
  let input = self.read_input()
  call self.label_clear()

  while 1
    " Tab label or window label is chosen.
    for kind in [ 'tab', 'win']
      let num = s:_.get_ic(self['label2'. kind], input, s:NOT_FOUND)
      if num isnot s:NOT_FOUND
        call self['do_'.kind](num)
      endif
    endfor

    let action = get(self.conf['keymap'], input, 'cancel')
    let action_func = 'do_' . action
    if !s:_.is_Funcref(action_func)
      throw 'UNKNOWN_ACTION'
    endif
    call self[action_func]()
  endwhile
endfunction
"}}}

" Action:
function! s:cw.do_win(num) "{{{1
  let self.win_dest = a:num
  throw 'CHOSE'
endfunction

function! s:cw.do_tab(num) "{{{1
  call self.tab_choose(a:num)
  let self.wins = self.win_all()
  call self.label_show()
endfunction

function! s:cw.do_tab_first() "{{{1
  call self.do_tab(1)
endfunction

function! s:cw.do_tab_prev() "{{{1
  call self.do_tab(max([1, self.env.tab.cur - 1]))
endfunction

function! s:cw.do_tab_next() "{{{1
  call self.do_tab(min([tabpagenr('$'), self.env.tab.cur + 1]))
endfunction

function! s:cw.do_tab_last() "{{{1
  call self.do_tab(tabpagenr('$'))
endfunction

function! s:cw.do_win_land() "{{{1
  let self.win_dest = winnr()
  throw 'CHOSE'
endfunction

function! s:cw.do_previous() "{{{1
  if empty(self.previous)
    throw 'NO_PREVIOUS_WINDOW'
  endif

  let [ tab_dst, self.win_dest ] = self.previous
  call self.tab_choose(tab_dst)
  throw 'CHOSE'
endfunction

function! s:cw.do_swap() "{{{1
  if self.conf['swap']
    call self.do_previous()
  else
    let self.conf['swap'] = 1
    let self.wins = self.win_all()
    call self.label_show()
    return
  endif
endfunction

function! s:cw.do_swap_stay() "{{{1
  if self.conf['swap']
    call self.do_previous()
  else
    let self.conf['swap'] = 1
    if !has_key(self.conf, 'swap_stay')
      let self.conf['swap_stay'] = action ==# 'swap_stay'
    endif
    let self.wins = self.win_all()
    call self.label_show()
    return
  endif
endfunction

function! s:cw.do_cancel()
  call self.tab_choose(self.env_orig.tab.cur)
  call self.win_choose(self.env_orig.win.cur)
  throw 'CANCELED'
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

function! s:cw.label_show() "{{{1
  try
    let wins_save     = self.wins
    let wins_filtered = self.call_hook('filter_window', wins_save)
    let self.wins     = wins_filtered
  catch
    let self.wins = wins_save
  endtry

  let self.label2win = s:_.dict_create(self.conf.label, self.wins)
  let self.win2label = s:_.dict_create(self.wins, self.conf.label)

  if self.conf['statusline_replace']
    call self.statusline_replace()
  endif
  if self.conf['overlay_enable']
    call self.overlay.start(self.wins, self.conf)
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

function! s:cw.first_path() "{{{1
  if empty(self.wins)
    throw 'RETURN'
  endif
  if len(self.wins) is 1
    if self.conf['auto_choose']
      let self.win_dest = self.wins[0]
      throw 'CHOSE'
    elseif self.conf['return_on_single_win']
      throw 'RETURN'
    endif
  endif
endfunction
"}}}

" Tabline:
function! s:cw.tabline() "{{{1
  let R   = ''
  let pad = repeat(' ', self.conf['label_padding'])
  let sepalator = printf('%%#%s# ', self.color.Other)
  for tabnum in self.env.tab.all
    let color = tabpagenr() is tabnum
          \ ? self.color.LabelCurrent
          \ : self.color.Label

    let R .= printf('%%#%s# %s ', color,  pad . self.get_tablabel(tabnum) . pad)
    let R .= tabnum !=# self.env.tab.all[-1] ? sepalator : ''
  endfor
  let R .= printf('%%#%s#', self.color.Other)
  return R
endfunction

function! s:cw.get_tablabel(num) "{{{1
  return len(self.conf['tablabel']) > a:num
        \ ? self.conf['tablabel'][a:num-1]
        \ : '..'
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

function! s:cw.status() "{{{1
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
    call self.win_choose(self.win_dest)

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
