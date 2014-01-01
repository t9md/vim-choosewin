let s:font_list = map(range(33, 126), 'nr2char(v:val)')
let s:data_file = expand("<sfile>:h") . '/data/vertical'

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

" Data:
let s:data = {}
function! s:data.parse(file) "{{{1
  let fonts = copy(s:font_list)

  let D = {}
  for f in fonts | let D[f] = [] | endfor

  for line in readfile(a:file)
    if line =~# '\v^---'
      if empty(fonts)
        break
      endif
      let current_font = remove(fonts, 0)
      " echo ' ============='
      " echo '   ' . current_font
      " echo ' ============='
      continue
    endif
    call add(D[current_font], line)
    " echo line
  endfor
  return D
endfunction

function! s:data.table() "{{{1
  if !has_key(self, '_table')
    let self._table = self.parse(s:data_file)
  endif
  return self._table
endfunction
"}}}

" Font:
let s:font = {}
function! s:font.new(char, data) "{{{1
  let self._data   = a:data
  let self.height  = len(self._data)
  let self.width   = len(self._data[0])
  let self.pattern = self._pattern()
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

function! s:font._parse() "{{{1
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

function! s:font._pattern() "{{{1
  return '\v' . join(self._parse(), '|')
endfunction
"}}}

" Table:
let s:table = {}
function! s:table.init() "{{{1
  let self._data = s:data.table()
  let self._table = {}
  for [char, font] in map(copy(s:font_list), '[v:val, s:font.new(v:val, self._data[v:val])]')
    let self._table[char] = font
  endfor
  return self
endfunction

function! choosewin#font#table() "{{{1
  return s:table.init()._table
endfunction
"}}}

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif
let start = reltime()
" let font_table = choosewin#font#table()
" for s:n in range(20)
  call s:table.init()
" endfor
echo reltimestr(reltime(start))
" vim: foldmethod=marker
