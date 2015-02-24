" API:
function! choosewin#font#small() "{{{1
  return choosewin#font#table#small()
endfunction

function! choosewin#font#large() "{{{1
  return choosewin#font#table#large()
endfunction
"}}}

" Test:
if expand("%:p") !=# expand("<sfile>:p")
  finish
endif

function! s:Test(size)
  return choosewin#font#{a:size}()
endfunction

let R = s:Test('small')
PP R
" let R = s:Test('large')
" echo R

" vim: foldmethod=marker
