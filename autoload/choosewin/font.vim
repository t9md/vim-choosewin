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
" vim: foldmethod=marker
