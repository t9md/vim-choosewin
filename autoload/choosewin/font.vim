" Static Var:
" char list of ['!'..'~'].
let s:font_list  = map(range(33, 126), 'nr2char(v:val)')

" data file path
let s:font_large = expand("<sfile>:h") . '/data/large'
let s:font_small = expand("<sfile>:h") . '/data/small'

" Util:
let s:_ = choosewin#util#get()

function! s:scan_match(str, pat) "{{{1
  " Return List of index where pattern mached to string
  " ex)
  "   s:scan_match('   ##   ', '#') => [3, 4]
  "   s:scan_match('        ', '#') => []
  let R = []
  for [i, c] in map(split(a:str, '\zs'), '[v:key, v:val]')
    if c is a:pat
      call add(R, i)
    endif
  endfor
  return R
endfunction

"}}}

" Font:
function! s:font_new(data) "{{{1
  " Generate Font(=Dictionary) used by Overlay.
  let width  = len(a:data[0])
  let height = len(a:data)
  let [line_used, col_used, pattern] = s:pattern_gen(a:data)
  return {
        \ 'width':     width,
        \ 'height':    height,
        \ 'col_used':  col_used,
        \ 'line_used': line_used,
        \ 'pattern':   pattern,
        \ }
endfunction

function! s:pattern_gen(data) "{{{1
  " Return Regexp pattern font_data represent.
  " This Regexp can't use without replacing special vars like '%{L+1}, %{C+1} ..'
  let R = []
  let line_used = []
  let col_used = []
  for [i, val] in map(a:data, '[v:key, s:scan_match(v:val, "#")]')
    if empty(val)
      continue
    endif
    call extend(col_used, val)
    call add(line_used, i)
    call add(R, s:_parse_column(i, val))
  endfor
  let col_used = s:_.uniq(col_used)
  return [line_used, col_used, '\v' . join(R, '|')]
endfunction


function! s:_parse_column(line, column_list) "{{{1
  " c_base = previous column position
  let R = []
  let c_previous = -1
  for c in a:column_list
    if c is c_previous
      let R[-1] .= '.'
    else
      call add(R, '%{C+'. c .'}c.')
    endif
    let col_previous = c
  endfor

  let prefix = "%{L+". a:line ."}l"
  return join(map(R, 'prefix . v:val'), "|")
endfunction
"}}}

" Table:
function! s:read_data(file) "{{{1
  " file = font data file path
  " return Dictionary where key=char, val=fontdata as List.
  "   {
  "     '!': ['   ##   ', '   ##   ', '   ##   ', '        ', '   ##   '],
  "     '"': [' ##  ## ', ' ##  ## ', '  #  #  ', '        ', '        '],
  "     .......
  "   }
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
" let small_data = s:read_data(s:font_small)
let large_data = s:read_data(s:font_large)
" echo small_data
echo s:pattern_gen(large_data['H'])

" vim: foldmethod=marker
