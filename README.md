# vim-loclist-follow

## description
Use this plugin to enable automatic updating of the selected location list item based on the current cursor position. The nearest item with be selected.

Tested against Syntastic and Ale setups with dozens of unique / split buffer windows opened (and their respective location list windows open (and closed) and populated) with no noticable lag. Please report any issues.

## usage
Enabled globally via:
```
    let g:loclist_follow = 1
```
and toggled locally via `:LoclistFollowToggle()`

## installation
### autoload
```
  $ cp plugin/vim-loclist-follow.vim ~/.vim/autoload/
```
### VimPlug
```
  Plug 'elbeardmorez/vim-loclist-follow'
```
