let s:font_height        = 10
let s:font_width         = 16
let s:highlight_priority = 100
let s:render_width       = 100

let s:vim_options_global = {
      \ '&scrolloff': 0,
      \ }

let s:vim_options_buffer = {
      \ '&modified':   0,
      \ '&modifiable': 1,
      \ '&readonly':   0,
      \ '&buftype':    '',
      \ }

let s:vim_options_window = {
      \ '&wrap':         0,
      \ '&list':         0,
      \ '&foldenable':   0,
      \ '&conceallevel': 0,
      \ }

" Util:
function! s:intrpl(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
endfunction "}}}

function! s:str_split(str) "{{{1
  return split(a:str, '\zs')
endfunction

function! s:uniq(list) "{{{1
  let R = {}
  for l in a:list
    let R[l] = 1
  endfor
  return map(keys(R), 'str2nr(v:val)')
endfunction


function! s:buffer_options_set(bufnr, options) "{{{1
  let R = {}
  for [var, val] in items(a:options)
    let R[var] = getbufvar(a:bufnr, var)
    call setbufvar(a:bufnr, var, val)
    unlet var val
  endfor
  return R
endfunction

function! s:buffer_options_restore(bufnr, options) "{{{1
  for [var, val] in items(a:options)
    call setbufvar(a:bufnr, var, val)
    unlet var val
  endfor
endfunction

function! s:window_options_set(winnr, options) "{{{1
  let R = {}
  for [var, val] in items(a:options)
    let R[var] = getwinvar(a:winnr, var)
    call setwinvar(a:winnr, var, val)
    unlet var val
  endfor
  return R
endfunction

function! s:window_options_restore(winnr, options) "{{{1
  for [var, val] in items(a:options)
    call setwinvar(a:winnr, var, val)
    unlet var val
  endfor
endfunction

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
"}}}
function! s:include_multibyte_char(str) "{{{1
  return strlen(a:str) !=# s:strchars(a:str)
endfunction
"}}}

" Overlay:
let s:overlay = {}

function! s:overlay.init() "{{{1
  let self.hlter       = choosewin#highlighter#get()
  let self._font_table = choosewin#font#table()
  let self.color       = self.hlter.color
endfunction

function! s:overlay._fill_space(lines, width) "{{{1
  let width = (a:width + s:font_width) / 2
  for line in a:lines
    let line_s = getline(line)
    if self.conf['overlay_clear_multibyte'] && s:include_multibyte_char(line_s)
      let line_new = repeat(' ', width)
    else
      let line_new = substitute(line_s, "\t", repeat(" ", &tabstop), 'g')
      let line_new .= repeat(' ' ,max([ width - len(line_new), 0 ]))
    endif
    call setline(line, line_new)
  endfor
endfunction

function! s:overlay.setup_winvar() "{{{1
  for winnr in self.wins
    noautocmd execute winnr 'wincmd w'

    let wv         = {}
    let wv.winview = winsaveview()
    let wv.options = s:window_options_set(winnr, s:vim_options_window)
    let wv['w0']   = line('w0')
    let wv['w$']   = line('w0')

    " need to save orignal pos before line_middle
    let wv.pos_org  = getpos('.')
    keepjump normal! M
    let line_middle   = line('.')
    let line_s        = max([line_middle + 2 - s:font_height/2, 0])
    let line_e        = line_s + s:font_height - 1
    let col           = (winwidth(0) - s:font_width)/2

    let wv.pos_render = [ line_s, col ]
    let wv.matchids   = []
    let w:choosewin   = wv

    let b:choosewin.rendering_area += range(line_s, line_e)
    let b:choosewin.winwidth += [winwidth(0)]
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
endfunction

function! s:overlay.setup(wins, conf) "{{{1
  let self.conf           = a:conf
  let self.options_global = s:buffer_options_set(bufnr(''), s:vim_options_global)
  let self.font_idx       = 0
  let self.captions       = s:str_split(self.conf['label'])
  let self.wins           = a:wins
  let self.winnr_org      = winnr()
  let self.bufs           = s:uniq(tabpagebuflist(tabpagenr()))
  let self.buffer_save   = {}

  for bufnr in self.bufs
    call setbufvar(bufnr, 'choosewin', {
          \ 'rendering_area': [],
          \ 'winwidth': [],
          \ 'options': {},
          \ 'undofile': tempname()
          \ })
  endfor
endfunction

function! s:overlay.append_blankline() "{{{1
  for bufnr in self.bufs
    noautocmd execute bufwinnr(bufnr) 'wincmd w'
    execute 'wundo' b:choosewin.undofile
    call s:undobreak()
    let b:choosewin.options = s:buffer_options_set(bufnr, s:vim_options_buffer)
    call append(line('$'), map(range(100), '""'))
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
endfunction

function! s:overlay.fill_space()
  for bufnr in self.bufs
    noautocmd execute bufwinnr(bufnr) 'wincmd w'
    silent undojoin
    call self._fill_space(s:uniq(b:choosewin.rendering_area),
          \ max(b:choosewin.winwidth))
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
endfunction

function! s:overlay.show_label() "{{{1
  for winnr in self.wins
    noautocmd execute winnr 'wincmd w'
    call self.hl_shade()
    call self.hl_label(winnr ==# self.winnr_org)
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
  redraw
endfunction

function! s:overlay.next_font() "{{{1
  let FONT = self._font_table[self.captions[self.font_idx]]
  let self.font_idx += 1
  return FONT
endfunction

function! s:overlay.overlay(wins, label) "{{{1
  call self.setup(a:wins, a:label)
  call self.append_blankline()
  call self.setup_winvar()
  call self.fill_space()
  call self.show_label()
endfunction

function! s:overlay.restore_buffer()
  for bufnr in self.bufs
    noautocmd execute bufwinnr(bufnr) 'wincmd w'
    try
      if !exists('b:choosewin')
        continue
      endif
      if &modified
        noautocmd keepjump silent undo
      endif
      if filereadable(b:choosewin.undofile)
        silent execute 'rundo' b:choosewin.undofile
      else
        call s:undoclear()
      endif
      call s:buffer_options_restore(str2nr(bufnr), b:choosewin.options)
    catch
      unlet b:choosewin
    endtry
  endfor
endfunction

function! s:overlay.restore_window()
  for winnr in self.wins
    noautocmd execute winnr 'wincmd w'
    if !exists('w:choosewin') | continue | endif

    try
      for m_id in w:choosewin.matchids
        call matchdelete(m_id)
      endfor
      call setpos('.', w:choosewin.pos_org)
      call s:window_options_restore(str2nr(winnr), w:choosewin.options)
      call winrestview(w:choosewin.winview)
    catch
      unlet w:choosewin
    endtry
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
endfunction

function! s:overlay.restore() "{{{1
  try
    call self.restore_buffer()
    call self.restore_window()
  finally
    call s:buffer_options_restore(bufnr(''), self.options_global)
  endtry
endfunction

function! s:overlay.hl_shade() "{{{1
  if !self.conf['overlay_shade']
    return
  endif

  let mid = matchadd(self.color.Shade,
        \ s:intrpl('\v%{w0}l\_.*%{w$}l', { 'w0': line('w0'), 'w$': line('w$') })
        \ )
  call add(w:choosewin.matchids, mid)
endfunction

function! s:overlay.hl_label(is_current) "{{{1
  let pattern = s:intrpl(self.next_font().pattern, s:vars(w:choosewin.pos_render))
  let mid = matchadd(
        \ self.color[ a:is_current ? 'OverlayCurrent': 'Overlay' ],
        \ pattern,
        \ s:highlight_priority)
  call add(w:choosewin.matchids, mid)
endfunction

function! s:vars(pos) "{{{1
  let line = a:pos[0]
  let col  = a:pos[1]
  let R    = { 'line': line, 'col': col }

  for line_offset in range(0,10)
    let R['line+' . line_offset] = line + line_offset
  endfor

  for col_offset in range(0,16)
    let R['col+' . col_offset] = col + col_offset
  endfor
  return R
endfunction

function! s:overlay.get() "{{{1
  if !has_key(self, '_font_table')
    call s:overlay.init()
  endif
  return self
endfunction

function! choosewin#overlay#overlay(...) "{{{1
  call call(s:overlay.overlay, a:000, s:overlay)
endfunction

function! choosewin#overlay#get() "{{{1
  return s:overlay.get()
endfunction
"}}}

call s:overlay.init()
" vim: foldmethod=marker
