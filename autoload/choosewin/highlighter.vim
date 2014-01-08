let s:h = {}

function! s:h.init() "{{{1
  let self.hlmgr = choosewin#hlmanager#new('ChooseWin')
  let color = {}
  let color.Label          = self.hlmgr.register(g:choosewin_color_label)
  let color.LabelCurrent   = self.hlmgr.register(g:choosewin_color_label_current)
  let color.Overlay        = self.hlmgr.register(g:choosewin_color_overlay)
  let color.OverlayCurrent = self.hlmgr.register(g:choosewin_color_overlay_current)
  let color.Shade          = self.hlmgr.register(g:choosewin_color_shade)

  let color.Other = g:choosewin_label_fill
        \ ? color.Label : self.hlmgr.register(g:choosewin_color_other)
  let color.Land = self.hlmgr.register(g:choosewin_color_land)
  let self.color = color
endfunction

function! s:h.get() "{{{1
  if !has_key(self, 'hlmgr') | call s:h.init() | endif
  return self
endfunction

function! s:h.refresh() "{{{1
  if !has_key(self, 'hlmgr') | call s:h.init() | endif
  call self.hlmgr.refresh()
endfunction

function! choosewin#highlighter#get() "{{{1
  return s:h.get()
endfunction

function! choosewin#highlighter#refresh() "{{{1
  call s:h.refresh()
endfunction
