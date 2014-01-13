let s:h = {}

let s:TYPE_STRING = type('')

function! s:h.init() "{{{1
  let self.hls       = {}
  let self.match_ids = []
  let self.run_mode = has('gui_running') ? 'gui' : 'cterm'
  return self
endfunction

function! s:h.hlname_for(defstr) "{{{1
  for [hlname, defstr] in items(self.hls)
    if defstr == a:defstr
      return hlname
    endif
  endfor
  return ''
endfunction

function! s:h.register(color) "{{{1
  if type(a:color) ==# s:TYPE_STRING
    return a:color
  endif
  let defstr = self.hl_defstr(a:color)
  let hlname = self.hlname_for(defstr)
  if empty(hlname)
    let hlname = get(a:color, 'name', self.next_color())
    call self.define(hlname, defstr)
  endif
  return hlname
endfunction

function! s:h.define(hlname, defstr) "{{{1
  silent execute self.command(a:hlname, a:defstr)
endfunction

function! s:h.command(hlname, defstr) "{{{1
  let self.hls[a:hlname] = a:defstr
  return printf('highlight %s %s', a:hlname, a:defstr)
endfunction

function! s:h.refresh() "{{{1
  let colors = deepcopy(self.hls)
  call self.reset()
  for [hlname, defstr] in items(colors)
    call self.define(hlname, defstr)
  endfor
endfunction

function! s:h.next_color() "{{{1
  return printf( self.hl_prefix . '%03d', self.next_index())
endfunction

function! s:h.next_index() "{{{1
  return len(self.hls)
endfunction

function! s:h.clear() "{{{1
  for hl in self.colors()
    execute 'highlight ' . hl . ' NONE'
  endfor
endfunction

function! s:h.reset() "{{{1
  call self.clear()
  call self.init()
endfunction

function! s:h.list() "{{{1
  for hl in self.colors()
    execute 'highlight ' . hl
  endfor
endfunction

function! s:h.list_define() "{{{1
  let s = []
  for [hlname, defstr] in items(self.hls)
    call add(s, self.command(hlname, defstr))
  endfor
  return s
endfunction

function! s:h.colors() "{{{1
  return keys(self.hls)
endfunction

function! s:h.matchadd(group, pattern, ...) "{{{1
  let args = [ a:group, a:pattern ]
  if a:0 && type(a:1) == type(1)
    call add(args, a:1)
  endif
  let id = call('matchadd', args)
  call add(self.match_ids, id)
  return id
endfunction

function! s:h.matchdelete_all() "{{{1
  for id in self.match_ids
    call matchdelete(id)
  endfor
endfunction

function! s:h.matchdelete_ids(ids) "{{{1
  for id in a:ids
    call matchdelete(id)
  endfor
endfunction

function! s:h.hl_defstr(color) "{{{1
  let r = []
  if !empty(get(a:color, self.run_mode))
    let color = a:color[self.run_mode]
    if !empty(color[0])      | call add(r, self.run_mode . 'bg=' . color[0]) | endif
    if !empty(color[1])      | call add(r, self.run_mode . 'fg=' . color[1]) | endif
    if !empty(get(color, 2)) | call add(r, self.run_mode . '='   . color[2]) | endif
  endif
  return join(r)
endfunction "}}}

function! s:h.dump() "{{{1
  return PP(self)
endfunction

function! s:h.our_match() "{{{
  return filter(getmatches(), "v:val.group =~# '". self.hl_prefix . "'")
endfunction "}}}

function! choosewin#hlmanager#new(hl_prefix) "{{{1
  let o = deepcopy(s:h).init()
  let o.hl_prefix = a:hl_prefix
  return o
endfunction "}}}
" call s:h.init()

" vim: foldmethod=marker
