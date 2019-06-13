
" jump to nearest item in the location list based on current line
function! g:LoclistNearest() abort
    " short-circuits
    let ll = getloclist('')
    let l_ll = len(ll)
    if l_ll == 0
        return
    endif
    let pos = getpos('.')
    let ln = pos[1]
    if exists("b:loclist_follow_line") && b:loclist_follow_line == ln
        return
    endif
    let b:loclist_follow_line = ln

    " determine current nearest, assume last as optimum start, correct
    " and account for multiple items per line
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
    let idx_next = ((abs(get(ll, max([idx - 1, 0])).lnum - ln) <= abs(get(ll,idx).lnum - ln)) ? max([idx - 1, 0]) : idx)

    " set
    if idx_next < 0 || (exists("b:loclist_follow_pos") && b:loclist_follow_pos == idx_next + 1)
        return
    endif
    let b:loclist_follow_pos = idx_next + 1
    exe "ll " . b:loclist_follow_pos

    " cleanup
    call setpos(".", pos)
endfunction

" loclist follow nearest
if exists('g:loclist_follow') && g:loclist_follow == 1
    autocmd CursorMoved <buffer> call g:LoclistNearest()
endif
