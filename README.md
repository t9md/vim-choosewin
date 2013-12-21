# Choose window with number key
Aiming to mimic tmux's `display-pane` feature, which enables you to choose window interactively.

Its should be useful especially when you are working on high resolution wide display.
Since with wide display, you are likely to open multiple window and moving around window is a little bit tiresome.
This plugin help this window excursion simplify with

1. display window label on statusbar
2. read input from user
3. you can land window you choose

example Configuration
```Vim
nmap  -  <Plug>(choosewin)
```

[Animation](http://gifzo.net/fko2nB8V2R.gif)

# Note
This plugin use `&statusline` to display window label.
You also need to display window number always on statusbar.

here is example to display window number using [ezbar](https://github.com/t9md/vim-ezbar).

```Vim
let g:ezbar = {}
let g:ezbar.active = [
     " .... other status line parts here ...
      \ 'choosewin',
      \ ]
let g:ezbar.inactive = [
     " .... other status line parts here ...
      \ 'choosewin',
      \ ]

function! s:u.choosewin(_) "{{{3
  if !g:choosewin_active
    return
  endif
  return {
        \ 's': '    '. a:_ . '    ',
        \ 'c': { 'gui': ['ForestGreen', 'white', 'bold'], 'cterm': [ 9, 16] },
        \ }
endfunction

function! s:u._filter(layout) "{{{3
  if g:choosewin_active
    return filter(a:layout, 'v:val.name =~ "choosewin\\|__SEP__"')
  endif
  return a:layout
endfunction
```
