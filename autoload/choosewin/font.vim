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
  let [ height, pattern ] = s:font_parse(a:data)
  return {
        \ 'width':   width,
        \ 'height':  height,
        \ 'pattern': pattern,
        \ }
endfunction

function! s:font_parse(data) "{{{1
  let R = map(a:data, 's:scan_match(v:val, "#", 0, [])')
  call map(R,
        \ 's:_parse("%{line+".v:key."}l", v:val, -1, [])')
  call filter(R, '!empty(v:val)')
  return [len(a:data), '\v' . join(R, '|')]
endfunction

function! s:_parse(prefix, pos_list, c_base, R) "{{{1
  if empty(a:pos_list)
    return join(map(a:R, 'a:prefix . v:val'), "|")
  endif
  let c = a:pos_list[0]
  if c is (a:c_base + 1)
    let a:R[-1] .= '.'
  else
    let s = '%{col+' . c . '}c.'
    call add(a:R, "" . s)
  endif
  return s:_parse(a:prefix, a:pos_list[1:], c, a:R)
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

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

function! s:perf_test(cnt) "{{{1
  let start = reltime()
  for i in range(1, a:cnt)
    call choosewin#font#large()
    call choosewin#font#small()
  endfor
  echo a:cnt . ": " . reltimestr(reltime(start))
endfunction
call s:perf_test(20)

" vim: foldmethod=marker
