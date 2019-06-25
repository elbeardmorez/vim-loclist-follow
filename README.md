# vim-loclist-follow

## description
Use this plugin to enable automatic updating of the selected location list item based on the current cursor position. The item selected is determined by the target type which by default selects the nearest item. Both window local, and global 'quickfix' location lists are supported.

Tested against Syntastic and Ale setups with dozens of unique / split buffer windows opened (and their respective location list windows open (and closed) and populated) with no noticeable lag. Please report any issues.

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
When globally toggled, all buffers will be toggled unless they have been locally toggled off (via `:LoclistFollowToggle` / `let b:loclist_follow = 0`) - this buffer local variable state removes the buffer from the influence of global toggling. When globally disabled, locally enabling a buffer **will** enable the functionality locally and will not change the global state.

The global `g:loclist_follow_target` variable and its corresponding command for toggling `LoclistFollowTargetToggle` can be used to switch the target type between the following values:

- `nearest`  : targets the closest item to the cursor on a line basis
- `previous`  : targets the item under cursor, else the previous item in the list
- `next`  : targets the item under cursor, else the next item in the list
- `towards`  : targets the item under cursor, else the *next* item given the direction of your cursor movement
- `away`  : inverts the behaviour described for `towards`
- `last`  : where possible targets / retains the last *hit* item

## installation
#### autoload
```
  $ cp plugin/vim-loclist-follow.vim ~/.vim/autoload/
```
#### VimPlug
```
  Plug 'elbeardmorez/vim-loclist-follow'
```
