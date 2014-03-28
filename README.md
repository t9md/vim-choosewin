[日本語はこちら](https://github.com/t9md/vim-choosewin/blob/master/README-JP.md)

# Animated GIF

![Movie](http://gifzo.net/1A8QMzrbRp.gif)

# Land to window you choose.

Aiming to mimic tmux's `display-pane` feature, which enables you to choose window interactively.


This plugin should be useful especially when you are working on high resolution wide display.
Since with wide display, you are likely to open multiple window and moving around window is a little bit tiresome.


This plugin simplifies window excursion.


  1. Display window label on statusline or middle of each window (overlay).
  2. Read input from user.
  3. You can land window you choose.


Example configuration:


```vim
nmap  -  <Plug>(choosewin)
```


Additional configuration:


```vim
" if you want to use overlay feature
let g:choosewin_overlay_enable          = 1

" overlay font broke on mutibyte buffer?
let g:choosewin_overlay_clear_multibyte = 1
```

More configuration is explained in help file. See `:help choosewin`.

