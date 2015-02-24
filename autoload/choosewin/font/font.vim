" Util:
function! s:scan_match(str, pattern) "{{{1
  let R = []
  let start = 0
  while 1
    let m = match(a:str, a:pattern, start)
    if m ==# -1 | break | endif
    call add(R, m)
    let start = m + 1
  endwhile
  return R
endfunction
"}}}

" Font:
let s:font = {}

function! s:font.new(data) "{{{1
  let self._data   = a:data
  let self.width   = len(self._data[0])
  let [ self.height, self.pattern ] = self._parse()
  return self.info()
  " return deepcopy(self)
endfunction

function! s:font.info() "{{{1
  return {
        \ 'height':  self.height,
        \ 'width':   self.width,
        \ 'pattern': self.pattern,
        \ }
endfunction

" {
"   'height': 5,
"   'pattern':
"     '\v%{line+0}l%{col+3}c..|%{line+1}l%{col+3}c..|%{line+2}l%{col+3}c..|%{line+4}l%{col+3}c..',
"   'width': 8
" }
function! s:font._parse() "{{{1
  let height = 0
  let R = []
  for idx in range(0, len(self._data) - 1)
    let indexes = s:scan_match(self._data[idx], '#')
    let line_anchor = '%{line+' . idx . '}l'
    let lc = -1
    let s = ''
    for cc in indexes
      if (lc + 1) ==# cc
        let s .= '.'
      else
        if !empty(s)
          let s.= '|'
        endif
        let s .= line_anchor . '%{col+' . cc . '}c.'
      endif
      let lc = cc
      let height = idx + 1
    endfor
    call add(R, s)
  endfor
  let pattern = '\v' . join(filter(R, '!empty(v:val)') , '|')
  return [ height, pattern ]
endfunction
"}}}

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
      \ }

let R =  choosewin#font#font#new(s:data['H'])
echo PP(R)
" echo R.info()
" echo R.string()


" function! choosewin#font#font#new(...) "{{{1
  " return call(s:font.new, a:000, s:font)
" endfunction

" vim: foldmethod=marker
