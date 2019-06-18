
" jump to nearest item in the location list based on current line
function! s:LoclistNearest(bnr) abort
    " short-circuits
    if exists('b:loclist_follow') && !b:loclist_follow
        return
    endif
    if exists('b:loclist_follow_file') && b:loclist_follow_file != fnamemodify(bufname(''), ':p')
        return
    endif
    let ll = getloclist('')
    let l_ll = len(ll)
    if l_ll == 0
        return
    endif
    if a:bnr != ll[0].bufnr
        return
    endif
    let pos = getpos('.')
    let ln = pos[1]

    " determine current nearest, assume last as optimum start, correct
    " and account for multiple items per line

    " line
    let idx = 0
    if exists("b:loclist_follow_pos")
        let idx = min([l_ll - 1, b:loclist_follow_pos - 1])
    endif
    while get(ll, idx).lnum >= ln && idx > 0
        let idx -= 1
    endwhile
    while get(ll, idx).lnum < ln && idx < l_ll - 1
        let idx += 1
    endwhile
    " column
    if get(ll, idx).lnum == ln
        let col = pos[2]
        while idx + 1 < l_ll && get(ll, idx + 1).lnum == ln
            if abs(get(ll, idx + 1).col - col) < abs(get(ll, idx).col - col)
                let idx += 1
            elseif col > get(ll, idx + 1).col
                let idx += 1
            else
                break
            endif
        endwhile
    endif
    let idx_next = ((abs(get(ll, max([idx - 1, 0])).lnum - ln) < abs(get(ll,idx).lnum - ln)) ? max([idx - 1, 0]) : idx)

    " set
    if idx_next < 0 || (exists("b:loclist_follow_pos") && b:loclist_follow_pos == idx_next + 1)
        return
    endif
    let b:loclist_follow_pos = idx_next + 1
    exe "ll " . b:loclist_follow_pos
    call setpos(".", pos)
endfunction

" toggle follow locally
function! s:LoclistFollowToggle()
    if exists('b:loclist_follow')
        let b:loclist_follow = !b:loclist_follow
    else
        let b:loclist_follow = !g:loclist_follow
    endif
endfunction

" toggle follow globally
function! s:LoclistFollowGlobalToggle()
    if exists('g:loclist_follow')
        let g:loclist_follow = !g:loclist_follow
    else
        let g:loclist_follow = 1
    endif
endfunction

function! s:BufReadPostHook(file_) abort
    if getwininfo(win_getid())[0].quickfix == 1
        return
    endif
    autocmd! loclist_follow CursorMoved <buffer>
    unlet! b:loclist_follow
    unlet! b:loclist_follow_pos
    if exists('g:loclist_follow') && g:loclist_follow == 1
        " enable loclist-follow
        augroup loclist_follow
            autocmd CursorMoved <buffer> call s:LoclistNearest(expand('<abuf>'))
        augroup END
        let b:loclist_follow = 1
        let b:loclist_follow_file = a:file_
    endif
endfunction

" install loclist-follow
augroup loclist_follow
    autocmd!
    if exists('g:loclist_follow')
        autocmd BufReadPost * call s:BufReadPostHook(expand('<amatch>'))
    endif
augroup END

command! -bar LoclistFollowToggle call s:LoclistFollowToggle()
command! -bar LoclistFollowGlobalToggle call s:LoclistFollowGlobalToggle()
