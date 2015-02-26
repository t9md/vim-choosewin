" Vars:
let s:FONT_MAX = {
      \ 'small': { 'width':  5, 'height':  8 },
      \ 'large': { 'width': 16, 'height': 10 },
      \ }

let s:vim_options = {}
let s:vim_options.global = {
      \ '&cursorline': 0,
      \ '&scrolloff':  0,
      \ '&lazyredraw': 1,
      \ }
let s:vim_options.buffer = {
      \ '&modified':   0,
      \ '&modifiable': 1,
      \ '&readonly':   0,
      \ '&buftype':    '',
      \ }
let s:vim_options.window = {
      \ '&wrap':         0,
      \ '&list':         0,
      \ '&foldenable':   0,
      \ '&conceallevel': 0,
      \ }

" Util:
function! s:intrpl(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
endfunction

function! s:vars(pos, width, height) "{{{1
  let line = a:pos[0]
  let col  = a:pos[1]
  let R    = { 'line': line, 'col': col }

  for line_offset in range(0, a:height - 1)
    let R["L+" . line_offset] = line + line_offset
  endfor

  for col_offset in range(0, a:width)
    let R["C+" . col_offset] = col + col_offset
  endfor
  return R
endfunction

function! s:uniq(list) "{{{1
  let R = {}
  for l in a:list
    let R[l] = 1
  endfor
  return map(keys(R), 'str2nr(v:val)')
endfunction

function! s:debug(msg) "{{{1
  if !get(g:,'choosewin_debug')
    return
  endif
  if exists('*Plog')
    call Plog(a:msg)
  endif
endfunction
"}}}

" Options Operation:
let s:options = {}
let s:options.buffer = {}
let s:options.window = {}

function! s:options.buffer.set(bufnr, options) "{{{1
  let R = {}
  for [var, val] in items(a:options)
    let R[var] = getbufvar(a:bufnr, var)
    call setbufvar(a:bufnr, var, val)
    unlet var val
  endfor
  return R
endfunction

function! s:options.window.set(winnr, options) "{{{1
  let R = {}
  for [var, val] in items(a:options)
    let R[var] = getwinvar(a:winnr, var)
    call setwinvar(a:winnr, var, val)
    unlet var val
  endfor
  return R
endfunction
"}}}

" Undo:
function! s:undobreak() "{{{1
  let &undolevels = &undolevels
  " silent exec 'normal!' "i\<C-g>u\<ESC>"
endfunction

function! s:undoclear() "{{{1
  let undolevels_org = &undolevels
  let &undolevels = -1
  noautocmd execute "normal! a \<BS>\<Esc>"
  let &undolevels = undolevels_org
endfunction
"}}}

" Multi Byte Char Handling:
" s:strchars() "{{{1
if exists('*strchars')
  function! s:strchars(str)
    return strchars(a:str)
  endfunction
else
  function! s:strchars(str)
    return strlen(substitute(str, ".", "x", "g"))
  endfunction
endif

function! s:include_multibyte_char(str) "{{{1
  return strlen(a:str) !=# s:strchars(a:str)
endfunction
"}}}

" Overlay:
let s:Overlay = {}

function! s:Overlay.get() "{{{1
  if !has_key(self, '_font_table')
    call s:Overlay.init()
  endif
  return self
endfunction

function! s:Overlay.init() "{{{1
  let self._font_table       = {}
  let self._font_table.small = choosewin#font#small()
  let self._font_table.large = choosewin#font#large()
  let self.color             = choosewin#color#get()
endfunction

function! s:Overlay.start(wins, conf) "{{{1
  call self.setup(a:wins, a:conf)
  call self.setup_window()
  call self.setup_buffer()
  call self.label_show()
endfunction

function! s:Overlay.setup(wins, conf) "{{{1
  let self.conf           = a:conf
  let self.options_global = s:options.buffer.set(bufnr(''), s:vim_options.global)
  let self.wins           = a:wins
  let self.winnr_org      = winnr()
  let self.bufs           = s:uniq(tabpagebuflist(tabpagenr()))

  for bufnr in self.bufs
    call setbufvar(bufnr, 'choosewin', {
          \ 'render_lines': [],
          \ 'winwidth':     [],
          \ 'offset':       [],
          \ 'options':      {},
          \ 'undofile':     tempname(),
          \ })
  endfor
endfunction

function! s:Overlay.setup_window() "{{{1
  let font_idx = 0
  for winnr in self.wins
    noautocmd execute winnr 'wincmd w'

    let wv          = {}
    let wv.winnr    = winnr
    let wv.pos_org  = getpos('.')
    let wv.winview  = winsaveview()
    let wv.options  = s:options.window.set(winnr, s:vim_options.window)
    let wv['w0']    = line('w0')
    let wv['w$']    = line('w$')

    let font_size = self.conf['overlay_font_size'] isnot 'auto'
          \ ? self.conf['overlay_font_size'] 
          \ : winheight(0) > s:FONT_MAX.large.height ? 'large' : 'small'

    let char = self.conf['label'][font_idx]
    let font = self._font_table[font_size][char]
    let font_idx += 1
    let wv.font   = font
    let line_s    = line('w0') + max([ 1 + (winheight(0) - s:FONT_MAX[font_size].height)/2, 0 ])
    let line_e    = line_s + font.height - 1
    let col       = max([(winwidth(0) - s:FONT_MAX[font_size].width)/2 , 1 ])
    let offset    = col('.') - wincol()
    let col      += offset

    let wv.matchids = []
    let wv.pattern  = s:intrpl(font.pattern, s:vars([line_s, col], font.width, font.height))

    let w:choosewin = wv

    let b:choosewin.render_lines += range(line_s, line_e)
    let b:choosewin.offset       += [offset]
    let b:choosewin.winwidth     += [winwidth(0)]
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
endfunction


function! s:Overlay.setup_buffer() "{{{1
  for bufnr in self.bufs
    noautocmd execute bufwinnr(bufnr) 'wincmd w'

    execute 'wundo' b:choosewin.undofile
    let b:choosewin.options = s:options.buffer.set(bufnr, s:vim_options.buffer)
    call s:undobreak()

    let render_lines = s:uniq(b:choosewin.render_lines)
    let append         = max([max(render_lines) - line('$'), 0 ])
    call append(line('$'), map(range(append), '""'))
    call self._fill_space(render_lines, max(b:choosewin.winwidth),  max(b:choosewin.offset))
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
endfunction

function! s:Overlay._fill_space(lines, width, offset) "{{{1
  let width = (a:width + s:FONT_MAX.large.width) / 2 + a:offset
  for line in a:lines
    let line_s = getline(line)
    if self.conf['overlay_clear_multibyte'] && s:include_multibyte_char(line_s)
      let line_new = repeat(' ', width)
    else
      let line_new = substitute(line_s, "\t", repeat(" ", &tabstop), 'g')
      let line_new .= repeat(' ' , max([ width - len(line_new), 0 ]))
    endif
    call setline(line, line_new)
  endfor
endfunction

function! s:Overlay.label_show() "{{{1
  for winnr in self.wins
    noautocmd execute winnr 'wincmd w'

    " Shade overall window
    if !self.conf['overlay_shade']
      let pattern = '\v%'. w:choosewin['w0'] .'l\_.*%'. w:choosewin['w$'] .'l'
      call self.matchadd(self.color.Shade, pattern, self.conf['overlay_shade_priority'])
    endif

    " Hide Trailing white space.
    call self.matchadd(self.color.Shade,'\s\+$', self.conf['overlay_shade_priority'])

    " Show Label
    let label_color =
          \ w:choosewin['winnr'] is self.winnr_org ? 'OverlayCurrent': 'Overlay'
    call self.matchadd(self.color[label_color], w:choosewin.pattern, self.conf['overlay_label_priority'])
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
  redraw
endfunction
"}}}

" Overlay Restore:
function! s:Overlay.restore() "{{{1
  try
    call self.restore_buffer()
    call self.restore_window()
  finally
    call s:options.buffer.set(bufnr(''), self.options_global)
  endtry
endfunction

function! s:Overlay.restore_buffer() "{{{1
  for bufnr in self.bufs
    noautocmd execute bufwinnr(bufnr) 'wincmd w'
    try
      if !exists('b:choosewin') | continue | endif
      if &modified
        noautocmd keepjump silent undo
      endif
      if filereadable(b:choosewin.undofile)
        silent execute 'rundo' b:choosewin.undofile
      else
        call s:undoclear()
      endif
      call s:options.buffer.set(str2nr(bufnr), b:choosewin.options)
    catch
      unlet b:choosewin
    endtry
  endfor
endfunction

function! s:Overlay.restore_window() "{{{1
  for winnr in self.wins
    noautocmd execute winnr 'wincmd w'
    if !exists('w:choosewin')
      call s:debug('Overlay: w:choosewin not exist winnr = ' . winnr)
      continue
    endif

    try
      call map(w:choosewin.matchids,'matchdelete(v:val)')
      call s:options.window.set(winnr, w:choosewin.options)
      call winrestview(w:choosewin.winview)
      call setpos('.', w:choosewin.pos_org)
    catch
      call s:debug("Overlay:" . v:exception)
      unlet w:choosewin
    endtry
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
endfunction
"}}}

" Highight:
function! s:Overlay.matchadd(color, pattern, priority)
  call add(w:choosewin.matchids,
        \ matchadd(a:color, a:pattern, a:priority))
endfunction
"}}}
call s:Overlay.init()

" API:
function! choosewin#overlay#get() "{{{1
  return s:Overlay.get()
endfunction
"}}}

" vim: foldmethod=marker
