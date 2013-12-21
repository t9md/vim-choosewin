# アニメーションGIF

![Movie](http://gifzo.net/fko2nB8V2R.gif)

# 数字でウィンドウを選択する
tmux の `display-pane` 機能を模倣しようと思い、作りました。  
`display-pane` はウィンドウ(tmux用語ではpane)を対話的に数字で選択できる機能です。  

このプラグインは、高解像度の広いディスプレイで作業している時に、特に効果を発揮するでしょう。
広いディスプレイでは沢山のウィンドウを開きますが、ウインドウを渡り歩く作業は退屈で面倒です。
このプラグインはウィンドウを渡り歩く作業を少し楽にしてくれるでしょう。

1. ウィンドウラベルをステータラインに表示
NOTE: this is not what this plugin does, use `&statusline` feature. or use statusline plugin.

2. read input from user
3. you can land window you choose

example Configuration
```Vim
nmap  -  <Plug>(choosewin)
```

# Statusline update example
Easiest way is that setting `&statusline` to display window number.

```Vim
let &statusline .= '%{winnr()}'
```

Or with statusline pluglin like [ezbar](https://github.com/t9md/vim-ezbar),
dynamically show window number when choosewin is activated.

here is example configuration for ezbar.

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
