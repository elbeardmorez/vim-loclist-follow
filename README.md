# vim-loclist-follow

## description
Use this plugin to enable automatic updating of the selected location list item based on the current cursor position. The nearest item with be selected.

Tested against Syntastic and Ale setups with dozens of unique / split buffer windows opened (and their respective location list windows open (and closed) and populated) with no noticable lag. Please report any issues.

## usage
To enable this plugin's functionality the global `g:loclist_follow` variable **must** be explicitly set either on/off, likely through an rc file entry e.g.:
```
    let g:loclist_follow = 1
```
Then there are two variables which control the ultimate on/off per buffer state of this functionality, namely `g:loclist_follow` and `b:loclist_follow`, and these can be toggled via commands `:LoclistFollowGlobalToggle` and `:LoclistFollowToggle` respectively.

When globally enabled, any opened/read buffers will have the appropriate hook installed on the `CursorMoved(I)` event(s) (this can be verified via `:autocmd loclist_follow`). The events correspond to *normal* and *insert* modes and both are hooked by default. The global `g:loclist_follow_modes` variable can be configured to modify this behaviour by setting any combination of the mode mappings `n -> normal` and `i -> insert` e.g.:
```
    let g:loclist_follow_modes = 'n'            "[default: 'ni']
```
When globally toggled, all buffers will be toggled unless they have been locally toggled off (via `:LoclistFollow` / `let b:loclist_follow = 0`) - this buffer local variable state removes the buffer from the influence of global toggling. When globally disabled, locally enabling a buffer **will** enable the functionality locally and will not change the global state.

## installation
#### autoload
```
  $ cp plugin/vim-loclist-follow.vim ~/.vim/autoload/
```
#### VimPlug
```
  Plug 'elbeardmorez/vim-loclist-follow'
```
