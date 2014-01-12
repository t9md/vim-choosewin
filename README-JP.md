# アニメーションGIF

![Movie](http://gifzo.net/1A8QMzrbRp.gif)

# 選択したウィンドウに移動
tmux の `display-pane` 機能を模倣しようと思い、作りました。  
`display-pane` はウィンドウ(tmux用語ではpane)を対話的に数字で選択できる機能です。  

このプラグインは、高解像度の広いディスプレイで作業している時に、特に効果を発揮するでしょう。  
広いディスプレイでは沢山のウィンドウを開きますが、ウインドウを渡り歩く作業は退屈で面倒です。  
このプラグインはウィンドウを渡り歩く作業を少し楽にしてくれるでしょう。  

  1. ウィンドウラベルをステータライン or 各ウィンドウの中央(オーバーレイ)に表示
  2. ウィンドウ番号を読み取る
  3. 選択したウィンドウに移動

設定例
```Vim
nmap  -  <Plug>(choosewin)
```

追加的な設定項目
```Vim
" オーバーレイ機能を有効にしたい場合
let g:choosewin_overlay_enable          = 1

" オーバーレイ・フォントをマルチバイト文字を含むバッファでも綺麗に表示する。
let g:choosewin_overlay_clear_multibyte = 1
```

More configuration is explained in help file. see `:help choosewin`
