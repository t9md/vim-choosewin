let s:Color = {}

function! s:Color.init() "{{{1
  if has_key(self, 'mgr')
    return
  endif

  let mgr = choosewin#hlmanager#new('ChooseWin')
  let self.mgr = mgr
  let color_Label = mgr.register(g:choosewin_color_label)
  let color = {
        \ "Label":          color_Label,
        \ "LabelCurrent":   mgr.register(g:choosewin_color_label_current),
        \ "Overlay":        mgr.register(g:choosewin_color_overlay),
        \ "OverlayCurrent": mgr.register(g:choosewin_color_overlay_current),
        \ "Shade":          mgr.register(g:choosewin_color_shade),
        \ }

  let color.Other = g:choosewin_label_fill
        \ ? color_Label : self.mgr.register(g:choosewin_color_other)
  let color.Land = self.mgr.register(g:choosewin_color_land)
  let self.color = color
endfunction

function! s:Color.get() "{{{1
  call   self.init()
  return self.color
endfunction

function! s:Color.refresh() "{{{1
  call self.init()
  call self.mgr.refresh()
endfunction
"}}}

" API:
function! choosewin#color#get() "{{{1
  return s:Color.get()
endfunction

function! choosewin#color#refresh() "{{{1
  call s:Color.refresh()
endfunction
"}}}

" vim: foldmethod=marker
