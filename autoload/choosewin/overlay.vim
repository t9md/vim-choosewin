let s:font_height        = 10
let s:font_width         = 16
let s:highlight_priority = 1000
let s:render_width       = 100

let s:vim_options_buffer = {
      \ '&modified':   0,
      \ '&modifiable': 1,
      \ '&readonly':   0,
      \ '&wrap':       0,
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

function! s:undobreak() "{{{1
  let &undolevels = &undolevels
  " silent exec 'normal!' "i\<C-g>u\<ESC>"
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
    let line_new = substitute(getline(line), "\t", repeat(" ", &tabstop), 'g')
    let pad_num = max([ width - len(line_new), 0 ])
    call setline(line, line_new . repeat(' ', pad_num))
  endfor
endfunction

function! s:overlay.setup_winvar() "{{{1
  for winnr in self.wins
    noautocmd execute winnr 'wincmd w'

    let wv = {}

    if g:choosewin_overlay_unfold
      let wv.foldenable = &foldenable
      let &foldenable = 0
    endif

    let wv['w0']   = line('w0')
    let wv['w$']   = line('w0')

    " need to save orignal pos before line_middle
    let wv.pos_org = getpos('.')
    normal! M
    let line_middle = line('.')
    let line_s      = max([line_middle + 2 - s:font_height/2, 0])
    let line_e      = line_s + s:font_height - 1
    let col         = (winwidth(0) - s:font_width)/2

    let wv.pos_render = [ line_s, col ]
    let wv.matchids = []

    let w:choosewin = wv

    let b:choosewin.rendering_area += range(line_s, line_e)
    let b:choosewin.winwidth += [winwidth(0)]
  endfor
  noautocmd execute self.winnr_org 'wincmd w'
endfunction


function! s:overlay.setup(wins) "{{{1
  let self.scrolloff_save = &scrolloff
  let &scrolloff          = 0
  let self.font_idx       = 0
  let self.captions       = s:str_split(g:choosewin_label)
  let self.wins           = a:wins
  let self.winnr_org      = winnr()
  let self.bufs           = s:uniq(tabpagebuflist(tabpagenr()))

  for bufnr in self.bufs
    call setbufvar(bufnr, 'choosewin',
          \ { 'rendering_area': [], 'winwidth': [], 'options': {}, 'undofile': tempname() } )
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

function! s:overlay.next_font() "{{{1
  let FONT = self._font_table[self.captions[self.font_idx]]
  let self.font_idx += 1
  return FONT
endfunction

function! s:overlay.overlay(wins) "{{{1
  try
    call self.setup(a:wins)
    call self.append_blankline()
    call self.setup_winvar()
    call self.fill_space()

    for winnr in self.wins
      noautocmd execute winnr 'wincmd w'
      if g:choosewin_overlay_shade
        call add(w:choosewin.matchids, self.hl_shade())
      endif
      call add(w:choosewin.matchids,
            \ self.hl_label(winnr ==# self.winnr_org))
    endfor
  finally
    noautocmd execute self.winnr_org 'wincmd w'
    redraw
  endtry
endfunction

function! s:overlay.restore() "{{{1
  try
    for bufnr in self.bufs
      noautocmd execute bufwinnr(bufnr) 'wincmd w'
      " normal! g-
      silent undo
      call s:buffer_options_restore(str2nr(bufnr), b:choosewin.options)
      if filereadable(b:choosewin.undofile)
        silent execute 'rundo' b:choosewin.undofile
      endif
      unlet b:choosewin
    endfor

    for winnr in self.wins
      noautocmd execute winnr 'wincmd w'
      for m_id in w:choosewin.matchids
        call matchdelete(m_id)
      endfor
      call setpos('.', w:choosewin.pos_org)
      if g:choosewin_overlay_unfold
        let &foldenable = w:choosewin.foldenable
      endif
      unlet w:choosewin
    endfor

  finally
    noautocmd execute self.winnr_org 'wincmd w'
    let &scrolloff = self.scrolloff_save
  endtry
endfunction

function! s:overlay.hl_shade() "{{{1
  return matchadd(self.color.Shade,
        \ s:intrpl('\v%{w0}l\_.*%{w$}l', { 'w0': line('w0'), 'w$': line('w$') })
        \ )
endfunction

function! s:overlay.hl_label(is_current) "{{{1
  let pattern = s:intrpl(self.next_font().pattern, s:vars(w:choosewin.pos_render))
  return matchadd(
        \ self.color[ a:is_current ? 'OverlayCurrent': 'Overlay' ],
        \ pattern,
        \ s:highlight_priority)
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
