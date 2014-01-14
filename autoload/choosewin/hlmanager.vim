let s:TYPE_STRING     = type('')
let s:TYPE_DICTIONARY = type({})
let s:TYPE_NUMBER     = type(0)
let s:GUI = has("gui_running")

let s:hlmgr = {}
function! s:hlmgr.init(prefix) "{{{1
  let self._store  = {}
  let self._prefix  = a:prefix
  return self
endfunction

function! s:hlmgr.register(dict, ...) "{{{1
  let defstr = self.hl_defstr(a:dict)
  let name = self.find_name(defstr)
  if !empty(name) | return name | endif
  let name = self.color_name_next()
  return self.define(name, { 'data': a:dict, 'defstr': defstr })
endfunction

function! s:hlmgr.define(name, data) "{{{1
  let self._store[a:name]  = a:data
  execute s:hlmgr.command(a:name, a:data.defstr)
  return a:name
endfunction

function! s:hlmgr.find_name(defstr) "{{{1
  for [name, color] in items(self._store)
    if color.defstr ==# a:defstr
      return name
    endif
  endfor
  return ''
endfunction

function! s:hlmgr.command(name, defstr) "{{{1
  return printf('highlight %s %s', a:name, a:defstr)
endfunction

function! s:hlmgr.refresh() "{{{1
  for [name, color] in items(self._store)
    call self.define(name, color)
  endfor
endfunction

function! s:hlmgr.color_name_next() "{{{1
  return printf( self._prefix . '%03d', len(self._store))
endfunction

function! s:hlmgr.clear() "{{{1
  for color in self.colors()
    execute 'highlight clear' color
  endfor
endfunction

function! s:hlmgr.colors() "{{{1
  return keys(self._store)
endfunction

function! s:hlmgr.hl_defstr(color) "{{{1
  " return 'guibg=DarkGreen gui=bold' (Type: String)
  let R = []
  let screen = s:GUI ? 'gui' : 'cterm'

  let color = a:color[screen]
  "[NOTE] empty() is not appropriate, cterm color is specified with number
  for [idx, s] in [[ 0, 'bg' ], [ 1, 'fg' ] ,[ 2, ''] ]
    let c = get(color, idx, -1)             
    if type(c) is s:TYPE_STRING && empty(c) 
      continue                              
    elseif type(c) is s:TYPE_NUMBER && c ==# -1
      continue                              
    endif                                   
    call add(R, printf('%s%s=%s', screen, s, color[idx]))
  endfor
  return join(R)
endfunction
                                                                         
function! choosewin#hlmanager#new(prefix) "{{{1
  return deepcopy(s:hlmgr).init(a:prefix)
endfunction "}}}
" vim: foldmethod=marker
