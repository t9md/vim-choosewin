let s:default = {
      \ 'statusline_replace':      1,
      \ 'tabline_replace':         1,
      \ 'overlay_enable':          0,
      \ 'overlay_font_size':       'auto',
      \ 'overlay_shade':           0,
      \ 'overlay_shade_priority':  100,
      \ 'overlay_label_priority':  101,
      \ 'overlay_clear_multibyte': 0,
      \ 'label_align':             'center',
      \ 'label_padding':           3,
      \ 'tablabel':                '123456789',
      \ 'blink_on_land':           1,
      \ 'return_on_single_win':    0,
      \ 'label':                   'ABCDEFGHIJKLMNOPQRTUVWXYZ',
      \ 'hook':                    {},
      \ 'hook_enable':             0,
      \ 'hook_bypass':             [],
      \ 'land_char':               ';',
      \ 'active':                  0,
      \ 'debug':                   0,
      \ }

let s:default.keymap = {
      \ '0':     'tab_first',
      \ '[':     'tab_prev',
      \ ']':     'tab_next',
      \ '$':     'tab_last',
      \ ';':     'win_land',
      \ '-':     'previous',
      \ 's':     'swap',
      \ 'S':     'swap_stay',
      \ "\<CR>": 'win_land',
      \ }

" These are variables cannot set directly via global variable.
let s:internal = {
      \ 'swap':        0,
      \ 'auto_choose': 0,
      \ 'noop':        0,
      \ }

" Config:
let s:config = {}

function! s:config.user() "{{{1
  let R = {}
  let prefix = 'choosewin_'
  for [name, val] in items(s:default)
    let R[name] = get(g:, prefix . name, val)
    unlet val
  endfor
  return R
endfunction

function! s:config.get() "{{{1
  return extend(self.user(), s:internal)
endfunction
"}}}

" API:
function! choosewin#config#get() "{{{1
  return s:config.get()
endfunction


" Test:
" if expand("%:p") !=# expand("<sfile>:p")
  " finish
" endif
" echo PP(choosewin#config#get())

" vim: fdm=marker:

