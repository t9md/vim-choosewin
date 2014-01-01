" Util:
function! s:str_split(str) "{{{1
  return split(a:str, '\zs')
endfunction
"}}}

" Font:
let s:fonts = '!"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~'
let s:data_file = 'autoload/choosewin/font/data/vertical'

function! s:parse_datafile(file) "{{{1
  let fonts = s:str_split(s:fonts)

  let D = {}
  for f in fonts | let D[f] = [] | endfor

  for line in readfile(a:file)
    if line =~# '\v^---'
      if empty(fonts)
        break
      endif
      let current_font = remove(fonts,0)
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
"}}}

" Table:
let s:table = {}
function! s:table.get() "{{{1
  if !has_key(self, '_table')
    let self._table = s:parse_datafile(s:data_file)
  endif
  return self._table
endfunction

function! choosewin#font#table#get() "{{{1
  return s:table.get()
endfunction
"}}}

if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

echo PP( choosewin#font#table#get())
" vim: foldmethod=marker
