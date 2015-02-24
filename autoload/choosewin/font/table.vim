let s:font_list  = map(range(33, 126), 'nr2char(v:val)')
let s:font_large = expand("<sfile>:h") . '/data/large'
let s:font_small = expand("<sfile>:h") . '/data/small'

" Table:
let s:table = {}

function! s:table.new(data_file) "{{{1
  return map(
        \ self.read_data(a:data_file),
        \ 'choosewin#font#font#new(v:val)')
endfunction

function! s:table.read_data(file) "{{{1
  let fonts = copy(s:font_list)

  let R = {}
  for f in fonts
    let R[f] = []
  endfor

  let lines = readfile(a:file)
  while !empty(fonts)
    let char = remove(fonts, 0)
    while 1
      let line = remove(lines, 0)
      if line =~# '\v^---'
        break
      endif
      call add(R[char], line)
    endwhile
  endwhile
  return R
endfunction

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

echo PP(s:table.read_data(s:font_small))
finish
let R = s:table.new(s:font_large)
echo PP(R)
" for [key, ]
" for [char, font] in items(R)
  " echo [font.height, font.width]
" endfor
" vim: foldmethod=marker
