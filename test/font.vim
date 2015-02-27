" let font_table = choosewin#font#table()
let s:FONT_LARGE_WIDTH_MAX = 16
let s:FONT_SMALL_WIDTH_MAX =  8
let s:hl_shade_priority = 100
let s:hl_label_priority = 101

let s:_ = choosewin#util#get()

let s:test = {}                        
function! s:test.setup() "{{{1         
  unlet! b:choosewin
  unlet! w:choosewin
  let self.overlay = choosewin#overlay#get()
  let self.conf    = choosewin#config()
endfunction                            

function! s:test.check() "{{{1         
  " let self.overlay = choosewin#overlay#get()
  " let self.conf    = choosewin#config()
  " echo s:_.str_split(self.conf['label'])
endfunction                            
                                       
function! s:test.review() "{{{1        
  call self.setup()                    

  for char in self.chars()
    let self.conf.label = char
    call self.overlay.start([1], self.conf)
    sleep 20m
    call self.overlay.restore()
  endfor
endfunction

function! s:test.chars() "{{{1        
  return map(range(33, 126), 'nr2char(v:val)')
endfunction

function! s:test.perf(size, count) "{{{1
  let g:choosewin_overlay_font_size = a:size
  call self.setup()                    
  let start = reltime()
  
  for n in range(a:count)
    for char in self.chars()
      let self.conf.label = char
      call self.overlay.start([1], self.conf)
      " sleep 20m
      call self.overlay.restore()
    endfor
  endfor

  let result = 'cnt='. a:count .' '. a:size .':'. reltimestr(reltime(start))
  echom result
endfunction

command! FontReview call s:test.review()
command! -count=1 FontPerfLarge call s:test.perf('large', <count>)
command! -count=1 FontPerfSmall call s:test.perf('small', <count>)

" NEW
" --------------------------
" FontPerfLarge
" cnt=3 large: 13.211046
" cnt=3 large: 13.317207 

" FontPerfSmall
" cnt=3 small: 11.024480
" cnt=3 small: 10.595363

" OLD
" --------------------------
" FontPerfLarge
" cnt=3 large: 26.530380

" FontPerfSmall
" cnt=3 small: 26.280097 

" vim: foldmethod=marker
