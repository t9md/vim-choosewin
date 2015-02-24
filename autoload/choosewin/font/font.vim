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
let s:font = {}

function! s:font.new(data) "{{{1
  let width = len(a:data[0])
  let [ height, pattern ] = s:parse(a:data)
  return {
        \ 'width':   width,
        \ 'height':  height,
        \ 'pattern': pattern,
        \ }
endfunction

" H
" {
"   'height': 5,
"   'pattern':
"     '\v%{line+0}l%{col+1}c..|%{line+0}l%{col+5}c..|%{line+1}l%{col+1}c..|%{line+1}l%{col+5}c..|%{line+2}l%{col+1}c......|%{line+3}l%{col+1}c..|%{line+3}l%{col+5}c..|%{line+4}l%{col+1}c..|%{line+4}l%{col+5}c..',
"   'width': 8
" }
function! s:parse(data) "{{{1
  let height = 0
  let R = []
  let pos_list = map(copy(a:data), 's:scan_match(v:val, "#", 0, [])')

  for [i, v] in map(pos_list, '[v:key, v:val]')
    if empty(v)
      continue
    endif

    let height   = i+1
    let L_anchor = '%{line+' . i . '}l'
    let last_col = -1

    let s = ""
    while !empty(v)
      let col_base = remove(v, 0)
      let s .= L_anchor . '%{col+' . col_base . '}c.'

      while !empty(v)
        " take
        let col = remove(v, 0)
        if col isnot (col_base+1)
          let s .= '|'
          " back
          call insert(v, col)
          break
        endif
        let s .= '.'
        let col_base += 1
      endwhile
    endwhile
    call add(R, s)
  endfor
  let pattern = '\v' . join(filter(R, '!empty(v:val)') , '|')
  return [ height, pattern ]
endfunction
" }}}

" API:
function! choosewin#font#font#new(...) "{{{1
  return call(s:font.new, a:000, s:font)
endfunction

" Test:
if expand("%:p") !=# expand("<sfile>:p")
  finish
endif
let s:data = {
      \ '!': ['   ##   ', '   ##   ', '   ##   ', '        ', '   ##   '],
      \ 'H': [' ##  ## ', ' ##  ## ', ' ###### ', ' ##  ## ', ' ##  ## '],
      \ '"': ['  ##  ##        ', '  ##  ##        ', '  ##  ##        ', '                ', '                ', '                ', '                ', '                ', '                ', '                ']
      \ }

echo s:parse(deepcopy(s:data['H']))
echo s:parse_old(deepcopy(s:data['H']))
finish
" let R = choosewin#font#font#new(s:data['"'])
" echo R
" finish
finish
let table_small = choosewin#font#table#small()
echo table_small
finish
" let table_small = map(table_small, 'v:val.height')
" echo  table_small

let table_small2 = choosewin#font#table#small2()
let table_small2 = map(table_small2, 'v:val.height')
echo len(table_small)
echo len(table_small2)
let DIFF = []
for [k, v] in items(table_small)
  let new = table_small2[k]
  if v isnot new
    call add(DIFF, [k, v, new])
  endif
endfor
echo DIFF
" echo (table_small is table_small2)
echo '----------------------------'

let table_large  = choosewin#font#table#large()
let table_large  = map(table_large, 'v:val.height')
let table_large2 = choosewin#font#table#large2()
let table_large2 = map(table_large2, 'v:val.height')
echo len(table_large)
echo len(table_large2)
let DIFF = []
for [k, v] in items(table_large)
  let new = table_large2[k]
  if v isnot new
    call add(DIFF, [k, v, new])
  endif
endfor
echo DIFF

" echo map(copy(s:data['H']), 's:scan_match(v:val, "#", 0, [])')
finish
" {'pattern': '\v%{line+0}l%{col+1}c..|%{line+0}l%{col+5}c..|%{line+1}l%{col+1}c..|%{line+1}l%{col+5}c..|%{line+2}l%{col+1}c......|%{line+3}l%{col+1}c..|%{line+3}l%{col+5}c..|%{line+4}l%{col+1}c..|%{line+4}l%{col+5}c..', 'width': 8, 'height': 5}
" for d in s:data['H']
  " echo s:scan_match(d, '#')
" endfor
" [1, 2, 5, 6]
" [1, 2, 5, 6]
" [1, 2, 3, 4, 5, 6]
" [1, 2, 5, 6]
" [1, 2, 5, 6]

" echo PP(R)
" echo R.info()
" echo R.string()


" function! choosewin#font#font#new(...) "{{{1
  " return call(s:font.new, a:000, s:font)
" endfunction

" vim: foldmethod=marker
