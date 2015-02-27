function! s:SID() "{{{1
  let fullname = expand("<sfile>")
  return matchstr(fullname, '<SNR>\d\+_')
endfunction
"}}}
let s:sid = s:SID()

" s:uniq() "{{{1
if exists('*uniq')
  function! s:uniq(...)
    return call('uniq', a:000 )
  endfunction
else
  function! s:uniq(list) "{{{1
    " implementation is not exactly same, this version of uniq is not affect
    " of original argment(list).
    let R = []
    for e in a:list
      if index(R, e) is -1
        call add(R, e)
      endif
    endfor
    return R
  endfunction
endif
"}}}


function! s:debug(msg) "{{{1
  if !get(g:,'choosewin_debug')
    return
  endif
  if exists('*Plog')
    call Plog(a:msg)
  endif
endfunction


function! s:buffer_options_set(bufnr, options) "{{{1
  let R = {}
  for [var, val] in items(a:options)
    let R[var] = getbufvar(a:bufnr, var)
    call setbufvar(a:bufnr, var, val)
    unlet var val
  endfor
  return R
endfunction

function! s:window_options_set(winnr, options) "{{{1
  let R = {}
  for [var, val] in items(a:options)
    let R[var] = getwinvar(a:winnr, var)
    call setwinvar(a:winnr, var, val)
    unlet var val
  endfor
  return R
endfunction
"}}}

" s:strchars() "{{{1
if exists('*strchars')
  function! s:strchars(str)
    return strchars(a:str)
  endfunction
else
  function! s:strchars(str)
    return strlen(substitute(str, ".", "x", "g"))
  endfunction
endif
"}}}

function! s:include_multibyte_char(str) "{{{1
  return strlen(a:str) !=# s:strchars(a:str)
endfunction

function! s:str_split(str) "{{{1
  return split(a:str, '\zs')
endfunction

function! s:define_type_checker() "{{{1
  " dynamically define s:is_Number(v)  etc..
  let types = {
        \ "Number":     0,
        \ "String":     1,
        \ "Funcref":    2,
        \ "List":       3,
        \ "Dictionary": 4,
        \ "Float":      5,
        \ }

  for [type, number] in items(types)
    let s = ''
    let s .= 'function! s:is_' . type . '(v)' . "\n"
    let s .= '  return type(a:v) ==# ' . number . "\n"
    let s .= 'endfunction' . "\n"
    execute s
  endfor
endfunction
"}}}
call s:define_type_checker()
unlet! s:define_type_checker


function! s:get_ic(table, char, default) "{{{1
  " get ignore case
  let i = index(keys(a:table), a:char, 0, 1)
  if i is -1
    return a:default
  endif
  return items(a:table)[i][1]
endfunction
"}}}


let s:functions = [
      \ "debug",
      \ "uniq",
      \ "str_split",
      \ "buffer_options_set",
      \ "window_options_set",
      \ "strchars",
      \ "include_multibyte_char",
      \ "is_Number",
      \ "is_String",
      \ "is_Funcref",
      \ "is_List",
      \ "is_Dictionary",
      \ "is_Float",
      \ "get_ic",
      \ ]

function! choosewin#util#get() "{{{1
  let R = {}
  for fname in s:functions
    let R[fname] = function(s:sid . fname)
  endfor
  return R
endfunction
"}}}
