[日本語はこちら](https://github.com/t9md/vim-choosewin/blob/master/README-JP.md)

# Animated GIF

![gif](https://raw.githubusercontent.com/t9md/t9md/85fd33b76f9a1a8b4d2d6993a6ab443d9cb2aebf/img/vim-smalls.gif)

# Land to window you choose.

Aiming to mimic tmux's `display-pane` feature, which enables you to choose window interactively.

This plugin should be useful especially when you are working on high resolution wide display.
Since with wide display, you are likely to open multiple window and moving around window is a little bit tiresome.

This plugin simplifies window excursion.

  1. Display window label on statusline or middle of each window (overlay).
  2. Read input from user.
  3. land to window.

## Example configuration:


```Vim
" invoke with '-'
nmap  -  <Plug>(choosewin)
```

Optional configuration:

```vim
" if you want to use overlay feature
let g:choosewin_overlay_enable = 1
```

More configuration is explained in help file. See `:help choosewin`.

## Default keymap in choosewin mode

| Key    | Action    | Description                   |
| ------ | --------- | ----------------------------- |
| 0      | tab_first | Choose FIRST    tab           |
| [      | tab_prev  | Choose PREVIOUS tab           |
| ]      | tab_next  | Choose NEXT     tab           |
| $      | tab_last  | Choose LAST     tab           |
| x      | tab_close | Close current tab             |
| ;      | win_land  | Land to current window        |
| `<CR>` | win_land  | Land to current window        |
| -      | previous  | Land to previous window       |
| s      | swap      | Swap window                #1 |
| S      | swap_stay | Swap window but stay       #1 |
|        | `<NOP>`   | Disable predefined keymap     |
*1 if you chose 'swap' again, swapping with previous window's buffer
ex) with default keymap, double 's'(ss) swap with previous buffer.

## Operational example

Assume you mapped `-` to invoke choosewin feature with following commands,

```Vim
nmap - <Plug>(choosewin)
```

### Move around tab, and choose window

First of all, open multiple windows and tabs.
Invoke choosewin with typing `-` in normal mode.  
Then you can move around tabs by `]` and `[` or directly choose target tab by number labeled on tabline.  
After you chose target tab, you can choose target window by typing alphabet which is labeled on statusline or on middle of window(if you enabled overlay feature).  

### Choose previouse window

Type `-` again to invoke choosewin, then input `-` again to choose previous window, previous window is the window last time you were on before you choose current window.  

### Swap window

Type `-` to invoke choosein, then type `s` to swap window.  
Then choose target window label you want to swap content(=buffer) of window with buffer of current window.  
After you chose, the current window's buffer is swapped with the buffer shown in the window you chose.  
By combinating swap and previous window, you can easily swap window with previous window like `-s-`, invoking choosewin itself(`-`) then enter swapping mode(`s`), then instruct choosewin that target window is previous(`-`) window. conguratulation!  
