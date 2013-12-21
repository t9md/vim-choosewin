" GUARD:
if expand("%:p") ==# expand("<sfile>:p")
  unlet! g:loaded_choosewin
endif
if exists('g:loaded_choosewin')
  finish
endif
let g:loaded_choosewin = 1
let s:old_cpo = &cpo
set cpo&vim

" Main:
function! s:echohl(msg)
  echohl PreProc
  echon a:msg
  echohl Normal
endfunction

let g:choosewin_active = 0

function! s:update_status(num) "{{{1
  let g:choosewin_active = a:num
  let &ro = &ro
  redraw
endfunction

function! s:choosewin(...) "{{{1
  call s:update_status(1)

  let winnums = range(1, winnr('$'))
  call s:echohl('select-window > ')
  try
    let num = str2nr(nr2char(getchar()))
    if index(winnums, num) ==# -1
      return
    endif
    silent execute  num . 'wincmd w'
  finally
    echo ''
    call s:update_status(0)
  endtry
endfunction
"}}}

" KeyMap:
nnoremap <silent> <Plug>(choosewin)  :<C-u>call <SID>choosewin()<CR>

" Command:
command! -nargs=? choosewin :call <SID>choosewin(<f-args>)

" Finish:
let &cpo = s:old_cpo
" vim: foldmethod=marker
