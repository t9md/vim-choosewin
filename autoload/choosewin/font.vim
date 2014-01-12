let s:font_list = map(range(33, 126), 'nr2char(v:val)')
let s:font_large = expand("<sfile>:h") . '/data/large'
let s:font_small = expand("<sfile>:h") . '/data/small'

" Util:
function! s:str_split(str) "{{{1
  return split(a:str, '\zs')
endfunction

function! s:scan_match(str, pattern) "{{{1
  let R = []
  let start = 0
  while 1
    let m = match(a:str, a:pattern, start)
    if m ==# -1 | break | endif
    call add(R, m)
    let start = m + 1
  endwhile
  return R
endfunction
"}}}

" Font:
let s:font = {}
function! s:font.new(char, data) "{{{1
  let self._data   = a:data
  let self.width   = len(self._data[0])
  let [ self.height, self.pattern ] = self._parse()
  return deepcopy(self)
endfunction

function! s:font.info() "{{{1
  return {
        \ 'data': self._data,
        \ 'height': self.height,
        \ 'width': self.width,
        \ 'pattern': self.pattern,
        \ }
endfunction

function! s:font.print() "{{{1
  return join(self._data, "\n")
endfunction

function! s:font._parse_old() "{{{1
  let R = []
  for idx in range(0, len(self._data) - 1)
    let indexes = s:scan_match(self._data[idx], '\$')
    let line_anchor = '%{line+' . idx . '}l'
    let pattern = join(map(indexes,
          \ 'line_anchor . "%{col+" . v:val . "}c"'), '|')
    call add(R, pattern)
  endfor
  call filter(R, '!empty(v:val)')
  return R
endfunction

function! s:font._parse() "{{{1
  let height = 0
  let R = []
  for idx in range(0, len(self._data) - 1)
    let indexes = s:scan_match(self._data[idx], '#')
    let line_anchor = '%{line+' . idx . '}l'
    let lc = -1
    let s = ''
    for cc in indexes
      if (lc + 1) ==# cc
        let s .= '.'
      else
        if !empty(s)
          let s.= '|'
        endif
        let s .= line_anchor . '%{col+' . cc . '}c.'
      endif
      let lc = cc
      let height = idx + 1
    endfor
    call add(R, s)
  endfor
  let pattern = '\v' . join(filter(R, '!empty(v:val)') , '|')
  return [ height, pattern ]
endfunction
"}}}

" Table:
let s:table = {}
function! s:table.new(data_file) "{{{1
  let data = self.read_data(a:data_file)
  let R = {}
  for [char, font] in map(copy(s:font_list), '[v:val, s:font.new(v:val, data[v:val])]')
    let R[char] = font
  endfor
  return R
endfunction

function! s:table.read_data(file) "{{{1
  let fonts = copy(s:font_list)
  let R = {}
  for f in fonts | let R[f] = [] | endfor
  for line in readfile(a:file)
    if line =~# '\v^---'
      if empty(fonts)
        break
      endif
      let current_font = remove(fonts, 0)
      continue
    endif
    call add(R[current_font], line)
  endfor
  return R
endfunction

function! choosewin#font#large() "{{{1
  return s:table.new(s:font_large)
endfunction

function! choosewin#font#small() "{{{1
  return s:table.new(s:font_small)
endfunction
"}}}

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif


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
  call self.setup()
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
  echo reltimestr(reltime(start))
endfunction

function! s:test.view(pattern, vars) "{{{1
  return matchadd('Search',
        \ s:intrpl(a:pattern, a:vars))
endfunction

function! s:test.overlay(pattern, vars) "{{{1
  call matchdelete(matchadd('Search',
        \ s:intrpl(a:pattern, a:vars)))
endfunction

command! FontReview call s:test.review()
command! -count=1 FontPerfLarge call s:test.perf('large', <count>)
command! -count=1 FontPerfSmall call s:test.perf('small', <count>)
echo "OK"

finish

function! FontReview() "{{{1
  call clearmatches()
  let start = reltime()


  for n in range(1)
    for char in font_list
      " let pattern = font_table[char].pattern
      " echo string([ char, font_table[char].height ])
      " PP font_table[char]
      let large = font_large[char]
      let small = font_small[char]

      call s:view(large.pattern, s:vars([1, 1], large.height))
      call s:view(small.pattern, s:vars([1,17], small.height))
      redraw
      sleep 500m
      call clearmatches()
      " call s:overlay(pattern, vars)
    endfor
  endfor
  echo reltimestr(reltime(start))
endfunction
echo "OK"
" call Test()

" let A = choosewin#font#table()['A']

"}}}
"}}}
" vim: foldmethod=marker
