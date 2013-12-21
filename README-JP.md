# アニメーションGIF

![Movie](http://gifzo.net/fko2nB8V2R.gif)

# 数字でウィンドウを選択する
tmux の `display-pane` 機能を模倣しようと思い、作りました。  
`display-pane` はウィンドウ(tmux用語ではpane)を対話的に数字で選択できる機能です。  

このプラグインは、高解像度の広いディスプレイで作業している時に、特に効果を発揮するでしょう。
広いディスプレイでは沢山のウィンドウを開きますが、ウインドウを渡り歩く作業は退屈で面倒です。
このプラグインはウィンドウを渡り歩く作業を少し楽にしてくれるでしょう。

1. ウィンドウラベルをステータラインに表示
NOTE: これはこのプラグインでは提供しません。`&statusline` を使うか、ステータスラインプラグインで行います。

2. ウィンドウ番号を読み取る
3. 選択したウィンドウに移動

設定例
```Vim
nmap  -  <Plug>(choosewin)
```

# ステータスラインのアップデート例
最も簡単な方法はウィンドウ番号を常に表示するように `&statusline` を設定することです。

```Vim
let &statusline .= '%{winnr()}'
```

あるいは、[ezbar](https://github.com/t9md/vim-ezbar) の様なステータスラインプラグインを使用して
chooswin が有効になった時に動的にウィンドウ番号を表示しても良いでしょう。

以下は、ezbar を使用した例です。

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
