let s:supported_chars = join(map(range(33, 126), 'nr2char(v:val)'), '')

" Util:
function! s:intrpl2(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
endfunction "}}}

function! s:intrpl(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  let r = []
  for expr in s:scan(a:string, mark)
    call add(r, substitute(expr, '\v([a-z][a-z$0]*)', '\=a:vars[submatch(1)]', 'g'))
  endfor
  call map(r, 'eval(v:val)')
  return substitute(a:string, mark,'\=remove(r, 0)', 'g')
endfunction

function! s:str_split(str) "{{{1
  return split(a:str, '\zs')
endfunction

function! s:scan(str, pattern) "{{{1
  let ret = []
  let nth = 1
  while 1
    let m = matchlist(a:str, a:pattern, 0, nth)
    if empty(m)
      break
    endif
    call add(ret, m[1])
    let nth += 1
  endwhile
  return ret
endfunction

function! s:uniq(list) "{{{1
  let R = {}
  for l in a:list
    let R[l] = 1
  endfor
  return map(keys(R), 'str2nr(v:val)')
endfunction

function! s:getwinline(win, ...) "{{{1
  " getbufline() wrapper
  let args = [ winbufnr(a:win) ] + a:000
  return call(function('getbufline'), args)
endfunction

function! s:setbufline(expr, lnum, text) "{{{1
  " from tyru's gist
  " https://gist.github.com/tyru/571746/c98b31859760c6d0ccb41d4ee210ac32913ecc8e
  let oldnr = winnr()
  let winnr = bufwinnr(a:expr)
  try
    if oldnr == winnr
      silent! call setline(a:lnum, a:text)
    elseif winnr ==# -1
      silent split
      silent execute bufnr(a:expr) 'buffer'
      silent call setline(a:lnum, a:text)
      silent hide
    else
      execute winnr 'wincmd w'
      silent call setline(a:lnum, a:text)
    endif
  finally
    execute oldnr 'wincmd w'
  endtry
endfunction

function! s:append_space(str, maxlen) "{{{1
  let pad = a:maxlen - len(a:str)
  return (pad > 0) ? a:str . repeat(' ', pad) : a:str
endfunction

function! s:tab2space(str, tabstop) "{{{1
  return substitute(a:str, "\t", repeat(" ", a:tabstop), 'g')
endfunction

function! s:fill_space(list, tabstop, maxwidth) "{{{1
  return map(deepcopy(a:list), 's:append_space(s:tab2space(v:val, a:tabstop), a:maxwidth)')
endfunction
"}}}

" Overlay:
let s:overlay = {}
function! s:overlay.init() "{{{1
  let self.hlter = choosewin#highlighter#get()
  let self._font_table = choosewin#font#table()
  let self.color = self.hlter.color
endfunction

function! s:overlay.fill_space(line_s, line_e, width) "{{{1
  let lines_new = s:fill_space(
        \ getline(a:line_s, a:line_e), &tabstop, a:width)
  silent! undojoin
  call setline(a:line_s, lines_new)
endfunction

function! s:overlay.lines_restore(store) "{{{1
  for [lnum, content]  in items(a:store)
    call setline(lnum, content)
  endfor
endfunction

function! s:overlay.lines_preserve(line_s, line_e, store) "{{{1
  for line in range(a:line_s, a:line_e)
    if has_key(a:store, line)
      continue
    endif
    let a:store[line] = getline(line)
  endfor
endfunction

function! s:overlay.main(wins)
  try
    call self.overlay(a:wins)
    echo 'hogeohge >'
    call getchar()
  finally
    call self.restore()
  endtry
endfunction

let s:vim_options_buffer = {
      \ '&modified':   0,
      \ '&modifiable': 1,
      \ '&readonly':   0,
      \ }

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
  " call g:plog([ bufname(a:bufnr), getbufvar(a:bufnr, '&modifiable')])
  for [var, val] in items(a:options)
    call setbufvar(a:bufnr, var, val)
    unlet var val
  endfor
endfunction


function! s:overlay.overlay(wins) "{{{1
  let self.winnr_org = winnr()
  let self.wins      = a:wins
  let self.lines_org = {}
  let buffers = s:uniq(map(range(1, winnr('$')), 'winbufnr(v:val)'))
  for bufnr in buffers | let self.lines_org[bufnr] = {} | endfor
  let self.buffers = {}

  let captions = s:str_split(g:choosewin_label)
  try
    for bufnr in buffers
      noautocmd execute bufwinnr(bufnr) 'wincmd w'
      silent! undojoin
      call append(line('$'), map(range(100), '""'))
      let self.buffers[bufnr] = {
            \ 'lines': {},
            \ 'options': s:buffer_options_set(bufnr, s:vim_options_buffer),
            \ }
    endfor
    for winnr in self.wins
      noautocmd execute winnr 'wincmd w'
      let font   = self._font_table[remove(captions, 0)]
      let line_s = line('w0') + (winheight(0) - font.height)/2
      let line_e = line_s + font.height
      let col    = (winwidth(0) - font.width)/2

      call self.lines_preserve(line_s, line_e, self.lines_org[winbufnr(winnr)])
      call self.fill_space(line_s, line_e, col + font.width)
      if g:choosewin_overlay_shade
        call self.hl_shade()
      endif
      let vars = s:vars([line_s, col])
      call self.hl_label(
            \ vars,
            \ self.color[ (winnr ==# self.winnr_org) ? 'OverlayCurrent': 'Overlay' ],
            \ font.pattern )
      redraw
    endfor
  finally
    noautocmd execute self.winnr_org 'wincmd w'
  endtry
endfunction

function! s:overlay.restore()
  " call g:plog(self.buffers)

  try
    for winnr in self.wins
      noautocmd execute winnr 'wincmd w'
      call clearmatches()
      " call self.lines_restore(self.lines_org[winbufnr(winnr)])
    endfor

    for [ bufnr, saved ] in items(self.buffers)
      noautocmd execute bufwinnr(bufnr) 'wincmd w'
      call s:buffer_options_restore(str2nr(bufnr), saved.options)
      let line_e = line('$')
      let line_s = line_e - (100 - 1)
      " call g:plog(bufname(bufnr('')))
      silent undo

      " let cmd =  line_s . ',' . line_e . 'delete _'
      " execute cmd
      " call g:plog(cmd)
      " silent undo
    endfor
  finally
    let self.lines_org = {}
    noautocmd execute self.winnr_org 'wincmd w'
  endtry
endfunction

function! s:overlay.hl_shade() "{{{1
  let pat = s:intrpl2('%{w0}l\_.*%{w$}l', { 'w0': line('w0'), 'w$': line('w$') })
  " let pat = s:intrpl('%{w0}l\_.*%{w$}l', { 'w0': line('w0'), 'w$': line('w$') })
  call matchadd(self.color.Shade, '\v'. pat )
endfunction

function! s:overlay.hl_label(vars, color, pattern) "{{{1
  call matchadd(a:color,
        \ s:intrpl2(a:pattern, a:vars),
        \ 1000)
endfunction

function! s:vars(pos)
  let l = a:pos[0]
  let c = a:pos[1]
  let vars = { 'line': l, 'col': c }
  " height
  for l_offset in range(0,10)
    let vars['line+' . l_offset] = l + l_offset
  endfor
  " width
  for c_offset in range(0,16)
    let vars['col+' . c_offset] = c + c_offset
  endfor
  return vars
endfunction

function! s:overlay.get() "{{{1
  if !has_key(self, '_font_table')
    call s:overlay.init()
  endif
  return self
endfunction
"}}}

function! choosewin#overlay#overlay(...)
  call call(s:overlay.overlay, a:000, s:overlay)
endfunction

function! choosewin#overlay#get()
  return s:overlay.get()
endfunction

call s:overlay.init()
if expand("%:p") !=# expand("<sfile>:p")
  finish
endif
let g:choosewin_label = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
command! OverLay call s:overlay.main(range(1, winnr('$')))
" vim: foldmethod=marker
