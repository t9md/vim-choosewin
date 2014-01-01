" http://patorjk.com/software/taag/#p=display&h=0&v=0&f=Big%20Money-ne&t=!%22%23%24%25%26'()*%0A%2B%2C-.%2F01234%0A56789%3A%3B%3C%3D%3E%0A%3F%40ABCDEFGH%0AIJKLMNOPQR%0ASTUVWXYZ%5B%5C%0A%5D%5E_%60abcdef%0Aghijklmnop%0Aqrstuvwxyz%0A%7B%7C%7D~%0A
function! s:capture() range
  normal! gv
  normal! "xy
  let list = split(getreg('x'), "\n")
  let list = split(PP(list), "\n")
  let prefix = '\ '
  call map(list,
        \ 'v:key ==# 0 ? "let s:<`1`> = " . v:val : prefix . substitute(v:val, "\\v\\s+", "", "")')
  call setreg('x', join(list,"\n"), 'v')
endfunction
command! -nargs=? -range FontCapture call <SID>capture()
xnoremap <F9> :FontCapture<CR>
nnoremap <S-F9> "xp

let s:supported_chars = join(map(range(33, 126), 'nr2char(v:val)'), '')
echo s:supported_chars
finish

function! s:str_split(str) "{{{1
  return split(a:str, '\zs')
endfunction

function! s:font_source()
  return join(s:str_split(s:supported_chars), "\n")
endfunction
echo s:font_source()
" http://patorjk.com/software/taag/#p=display&f=3-D&t=abcdefghijklmnop%0Aqrstuvwxyz%7B%7C%7D!%0A
function! s:prepare_ascii(chars, take) "{{{1
  let S = ''
  let n = 0
  let m = n + a:take
  while !empty(a:chars[n : m-1])
    let S .= a:chars[n : m-1] . "\n"
    let n += a:take
    let m += a:take
  endwhile
  return S
endfunction

function! s:report() "{{{1
  echo s:supported_chars
  echo ''
  echo s:prepare_ascii(s:supported_chars, 10)
endfunction
