let s:font_list  = map(range(33, 126), 'nr2char(v:val)')
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

" Table:
let s:table = {}
function! s:table.new(data_file) "{{{1
  let data = self.read_data(a:data_file)
  let R = {}
  for [char, font] in map(copy(s:font_list), '[v:val, choosewin#font#font#new(v:val, data[v:val])]')
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
"}}}

" API:
function! choosewin#font#table#small() "{{{1
  return s:table.new(s:font_small)
endfunction

function! choosewin#font#table#large() "{{{1
  return s:table.new(s:font_large)
endfunction
"}}}

" Test:
if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

function! s:Test()
  return choosewin#font#table#small()
endfunction
let R = s:Test()
" vim: foldmethod=marker
