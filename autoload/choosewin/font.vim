" Static Var:
" char list of ['!'..'~'].
let s:font_list  = map(range(33, 126), 'nr2char(v:val)')

" data file path
let s:font_large = expand("<sfile>:h") . '/data/large'
let s:font_small = expand("<sfile>:h") . '/data/small'

" Util:
function! s:scan_match(str, pattern, start, R) "{{{1
  let m = match(a:str, a:pattern, a:start)
  if m is -1
    return a:R
  endif
  return s:scan_match(a:str, a:pattern, m + 1, add(a:R, m))
endfunction
"}}}

" Font:
function! s:font_new(data) "{{{1
  let width = len(a:data[0])
  let height = len(a:data)
  return {
        \ 'width':   width,
        \ 'height':  height,
        \ 'pattern': s:patern_gen(a:data),
        \ }
endfunction

function! s:patern_gen(data) "{{{1
  let R = map(a:data, 's:scan_match(v:val, "#", 0, [])')
  call map(R,
        \ 's:_parse("%{L+".v:key."}l", v:val, -1, [])')
  call filter(R, '!empty(v:val)')
  return '\v' . join(R, '|')
endfunction

function! s:_parse(prefix, pos_list, c_base, R) "{{{1
  " R = result
  " c_base = previous column position
  if empty(a:pos_list)
    return join(map(a:R, 'a:prefix . v:val'), "|")
  endif
  let col = remove(a:pos_list, 0)
  if col is (a:c_base + 1)
    let a:R[-1] .= '.'
  else
    call add(a:R, '%{C+' . col . '}c.')
  endif
  return s:_parse(a:prefix, a:pos_list, col, a:R)
endfunction
"}}}

" Table:
function! s:read_data(file) "{{{1
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
"}}}

" API:
function! choosewin#font#small() "{{{1
  return map(s:read_data(s:font_small),'s:font_new(v:val)')
endfunction

function! choosewin#font#large() "{{{1
  return map(s:read_data(s:font_large),'s:font_new(v:val)')
endfunction
"}}}

" vim: foldmethod=marker
