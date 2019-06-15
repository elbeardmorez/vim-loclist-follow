
" jump to nearest item in the location list based on current line
function! s:LoclistNearest() abort
    " short-circuits
    let ll = getloclist('')
    let l_ll = len(ll)
    if l_ll == 0
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

function! s:BufReadPostHook() abort
    if exists('g:loclist_follow') && g:loclist_follow == 1
        augroup loclist_follow
            autocmd! CursorMoved
            unlet! b:loclist_follow_pos
        augroup END
    endif
endfunction

function! s:BufWritePostHook() abort
    if exists('g:loclist_follow') && g:loclist_follow == 1
        " enable loclist-follow
        augroup loclist_follow
            autocmd CursorMoved <buffer> call s:LoclistNearest()
        augroup END
    endif
endfunction

" install loclist-follow
augroup loclist_follow
    autocmd!
    if exists('g:loclist_follow')
        autocmd BufReadPost * call s:BufReadPostHook()
        autocmd BufWritePost * call s:BufWritePostHook()
    endif
augroup END
