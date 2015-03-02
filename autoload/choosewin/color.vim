let s:Color = {}

function! s:Color.init() "{{{1
  if has_key(self, 'mgr')
    return
  endif
  let config = choosewin#config#get()

  let self.mgr = choosewin#hlmanager#new('ChooseWin')
  let color_Label = self.mgr.register(config['color_label'])
  let color = {
        \ "Label":          color_Label,
        \ "LabelCurrent":   self.mgr.register(config['color_label_current']),
        \ "Overlay":        self.mgr.register(config['color_overlay']),
        \ "OverlayCurrent": self.mgr.register(config['color_overlay_current']),
        \ "Shade":          self.mgr.register(config['color_shade']),
        \ }

  let color.Other = config['label_fill']
        \ ? color_Label : self.mgr.register(config['color_other'])
  let color.Land = self.mgr.register(config['color_land'])
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
