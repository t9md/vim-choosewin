" let font_table = choosewin#font#table()
let s:FONT_LARGE_WIDTH_MAX = 16
let s:FONT_SMALL_WIDTH_MAX =  8
let s:hl_shade_priority = 100
let s:hl_label_priority = 101

function! s:intrpl(string, vars) "{{{1
  let mark = '\v\{(.{-})\}'
  return substitute(a:string, mark,'\=a:vars[submatch(1)]', 'g')
endfunction

function! s:vars(pos, height, width) "{{{1
  let line = a:pos[0]
  let col  = a:pos[1]
  let R    = { 'line': line, 'col': col }

  for line_offset in range(0, a:height - 1)
    let R['line+' . line_offset] = line + line_offset
  endfor

  for col_offset in range(0, a:width)
    let R['col+' . col_offset] = col + col_offset
  endfor
  return R
endfunction

let s:test = {}
function! s:test.setup() "{{{1
  let self.table = {}
  let self.table.small = choosewin#font#small()
  let self.table.large = choosewin#font#large()
endfunction

function! s:test.font_list() "{{{1
  return map(range(33, 126), 'nr2char(v:val)')
endfunction

function! s:test.review() "{{{1
  call self.setup()
  let start = reltime()

  for char in self.font_list()
    call clearmatches()
    let large = self.table.large[char]
    let small = self.table.small[char]
    call self.view(large.pattern, s:vars([1, 1], large.height, large.width))
    call self.view(small.pattern, s:vars([1,17], small.height, small.width))
    redraw
    sleep 100m
  endfor

  echo reltimestr(reltime(start))
endfunction

function! s:test.perf(size, time) "{{{1
  if !has_key(self, 'table')
    call self.setup()
  endif
  let start = reltime()
  
  let vars = s:vars([1, 1], 16, 16 )
  let table = self.table[a:size]
  for n in range(a:time)
    for char in self.font_list()
      let font = table[char]
      " call self.overlay(font.pattern, s:vars([1, 1], font.height, font.width))
      call self.overlay(font.pattern, vars)
    endfor
  endfor
  let result = a:size . ':' . reltimestr(reltime(start))
  echom result
endfunction

function! s:test.perf_all(time) "{{{1
  call self.perf('large', a:time)
  call self.perf('small', a:time)
endfunction

function! s:test.view(pattern, vars) "{{{1
  return matchadd('Search',
        \ s:intrpl(a:pattern, a:vars))
endfunction

function! s:test.overlay(pattern, vars) "{{{1
  " redraw
  let id = matchadd('Search', s:intrpl(a:pattern, a:vars))
  call matchdelete(id)
endfunction

command! FontReview call s:test.review()
command! -count=1 FontPerfLarge call s:test.perf('large', <count>)
command! -count=1 FontPerfSmall call s:test.perf('small', <count>)
command! -count=1 FontPerfAll   call s:test.perf_all(<count>)
" vim: foldmethod=marker
