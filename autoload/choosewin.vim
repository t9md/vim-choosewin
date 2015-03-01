" Vars:
let s:vim_tab_options = {
      \ '&tabline':     '%!choosewin#tabline()',
      \ '&guitablabel': '%{choosewin#get_tablabel(v:lnum)}',
      \ }

" Util::
let s:_ = choosewin#util#get()

function! s:win_all() "{{{1
  return range(1, winnr('$'))
endfunction

function! s:tab_all() "{{{1
  return range(1, tabpagenr('$'))
endfunction
"}}}

" Env:
let s:env = {}

function! s:env.update() "{{{1
  return extend(self, {
        \ 'win_cur': winnr(),
        \ 'win_all': s:win_all(),
        \ 'tab_cur': tabpagenr(),
        \ 'tab_all': s:tab_all(),
        \ 'buf_cur': bufnr(''),
        \ })
endfunction
"}}}

" Main:
let s:cw = {}
function! s:cw.start(wins, ...) "{{{1
  let self.conf   = extend(choosewin#config#get(), get(a:000, 0, {}))
  let self.color  = choosewin#color#get()
  let self.action = choosewin#action#init(self)

  " Elminate non-exsiting window.
  let self.wins = filter(a:wins, 'index(s:win_all(), v:val) isnot -1')
  let status = []
  try
    " Some status bar plugin need to know if choosewin active or not.
    let g:choosewin_active = 1

    if empty(self.wins)
      throw 'RETURN'
    endif
    if len(self.wins) is 1
      call self.first_path()
    endif
    call self.setup()
    call self.choose()
  catch /\v^(CHOSE|SWAP)$/
    let status = [ tabpagenr(), winnr() ]
    let self.previous = [ self.env_org.tab_cur, self.env_org.win_cur ]
  catch /\v^(RETURN|CANCELED)$/
    let status = []
  catch
    let self.exception = v:exception
    let status = []
  finally
    call self.finish()
    let g:choosewin_active = 0
    return status
  endtry
endfunction

function! s:cw.setup() "{{{1
  let self.exception   = ''
  let self.win_dest    = ''
  let self.tab_options = {}
  let self.env         = s:env.update()
  let self.env_org     = deepcopy(self.env)
  let self.label2tab   = s:_.dict_create(self.conf['tablabel'], self.env.tab_all)
  " let self.tab2label   = s:_.dict_create(self.env.tab_all, self.conf['tablabel'])

  if !has_key(self, 'previous')
    let self.previous = []
  endif

  if self.conf['overlay_enable']
    let self.overlay = choosewin#overlay#get()
  endif

  if self.conf['tabline_replace']
    let self.tab_options = s:_.buffer_options_set(bufnr(''), s:vim_tab_options)
  endif
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
  let color = self.color[ winnr() is a:win ? "LabelCurrent" : "Label" ]

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

function! s:cw.choose() "{{{1
  while 1
    call self.label_show()
    let prompt = (self.conf['swap'] ? '[swap] ' : '') . 'chooose > '
    let char = s:_.read_char(prompt)

    call self.label_clear()

    " Tab label is chosen.
    let num = s:_.get_ic(self.label2tab, char)
    if !empty(num)
      call self.action.do_tab(num)
      continue
    endif

    " Win label is chosen.
    let num = s:_.get_ic(self.label2win, char)
    if !empty(num)
      if self.conf['swap']
        call self.action._swap(tabpagenr(), num)
      else
        call self.action.do_win(num)
      endif
    endif

    let action_name = 'do_' . get(self.conf['keymap'], char, 'cancel')
    if !s:_.is_Funcref(get(self.action, action_name))
      throw 'UNKNOWN_ACTION'
    endif
    call self.action[action_name]()
  endwhile
endfunction

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
    let wins_filtered = self.call_hook('filter_window', self.wins)
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
  if self.conf['return_on_single_win']
    throw 'RETURN'
  endif

  if self.conf['auto_choose']
    " never return
    call self.action.do_win(self.wins[0])
  endif
endfunction
"}}}

" Tabline:
function! s:cw.tabline() "{{{1
  let R   = ''
  let pad = repeat(' ', self.conf['label_padding'])
  let sepalator = printf('%%#%s# ', self.color.Other)
  let tab_all = s:tab_all()
  for tabnum in tab_all
    let color = self.color[ tabpagenr() is tabnum ? "LabelCurrent" : "Label" ]
    let R .= printf('%%#%s# %s ', color,  pad . self.get_tablabel(tabnum) . pad)
    let R .= tabnum isnot tab_all[-1] ? sepalator : ''
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

" Restore:
function! s:cw.finish() "{{{1
  if !empty(self.tab_options)
    call s:_.buffer_options_set(bufnr(''), self.tab_options)
  endif
  echo ''
  redraw
  if self.conf['blink_on_land']
    call s:_.blink(2, self.color.Land, '\k*\%#\k*')
  endif
  if !empty(self.exception)
    call s:_.message(self.exception)
  endif
endfunction
"}}}

" API:
function! choosewin#start(...) "{{{1
  return call(s:cw.start, a:000, s:cw)
endfunction

function! choosewin#tabline() "{{{1
  return s:cw.tabline()
endfunction

function! choosewin#get_tablabel(num) "{{{1
  return s:cw.get_tablabel(a:num)
endfunction
"}}}

" vim: foldmethod=marker
