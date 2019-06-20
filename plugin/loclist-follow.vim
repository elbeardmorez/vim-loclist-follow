
" defaults
let s:loclist_follow_modes = 'ni'
" mode event map
let s:loclist_follow_hook_events = {'n': 'CursorMoved', 'i': 'CursorMovedI'}

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
    if exists('b:loclist_follow_pos')
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
    if idx_next < 0 || (exists('b:loclist_follow_pos') && b:loclist_follow_pos == idx_next + 1)
        return
    endif
    let b:loclist_follow_pos = idx_next + 1
    exe 'll ' . b:loclist_follow_pos
    call setpos('.', pos)
endfunction

" retrieve list of selected hook events
function! s:LoclistFollowHookEvents()
    let modes = exists('g:loclist_follow_modes') ? g:loclist_follow_modes : s:loclist_follow_modes
    let l = 0
    let events = []
    while l < len(modes)
        let c = tolower(modes[l:l])
        if exists('s:loclist_follow_hook_events.' . c)
            call add(events, s:loclist_follow_hook_events[c])
        else
            echom('ignoring invalid mode type ''' . c . '''')
        endif
        let l += 1
    endwhile
    return events
endfunction

" toggle follow locally
function! s:LoclistFollowToggle(...)
    if !exists('g:loclist_follow')
        return
    endif

    "switch | -1: off, 0: auto, 1: on
    let switch = get(a:, 1, 0)

    "b:loclist_follow | -1: globally off, 0: locally off, 1: on
    let bv = 0
    if switch == 0
        if !exists('b:loclist_follow') || b:loclist_follow != 1
            let bv = 1
        endif
    elseif switch == 1
        let bv = 1
    endif

    let events = s:LoclistFollowHookEvents()
    let b:loclist_follow = bv
    if bv
        for ev in events
            execute 'autocmd loclist_follow' ev '<buffer=' . bufnr('') . '> call s:LoclistNearest(' . bufnr('') . ')'
        endfor
    else
        for ev in events
            execute 'autocmd! loclist_follow' ev '<buffer>'
        endfor
    endif
endfunction

" toggle follow globally
function! s:LoclistFollowGlobalToggle(...)
    if !exists('g:loclist_follow')
        return
    endif

    "switch | -1: off, 0: auto, 1: on
    let switch = get(a:, 1, 0)

    "g:loclist_follow | 0: globally off, 1: globally on
    let gv = 0
    if switch == 0
        if !exists('g:loclist_follow') || g:loclist_follow == 0
            let gv = 1
        endif
    elseif switch == 1
        let gv = 1
    endif

    let events = s:LoclistFollowHookEvents()
    let g:loclist_follow = gv
    if gv == 0
        "remove all hooks
        for ev in events
            execute 'autocmd! loclist_follow' ev
        endfor
    endif
    "ensure any touched are 'global switched' -1 <-> 1
    let touched = filter(getbufinfo(), {i, b -> exists('b.variables.loclist_follow') })
    let bv = (gv == 0 ? -1 : 1)
    for b in touched
        if b.variables.loclist_follow != 0
            call setbufvar(b.bufnr, 'loclist_follow', bv)
            if bv == 1
                "add hook to previously globally toggled buffer
                for ev in events
                    execute 'autocmd!' ev '<buffer=' . b.bufnr . '> call s:LoclistNearest(' . b.bufnr . ')'
                endfor
            endif
        endif
    endfor
endfunction

function! s:BufReadPostHook(file_) abort
    if !exists('g:loclist_follow')
        return
    endif
    if getwininfo(win_getid())[0].quickfix == 1
        return
    endif

    if g:loclist_follow == 1
        if !exists('b:loclist_follow')
            " enable loclist-follow
            call s:LoclistFollowToggle(1)
        endif
        if exists('b:loclist_follow_file') && b:loclist_follow_file != a:file_
            " reset
            unlet! b:loclist_follow_pos
        endif
        let b:loclist_follow_file = a:file_
    else
        call s:LoclistFollowToggle(-1)
        unlet! b:loclist_follow
        unlet! b:loclist_follow_file
    endif
endfunction

" install loclist-follow
augroup loclist_follow
    autocmd!
    if exists('g:loclist_follow')
        autocmd BufReadPost * call s:BufReadPostHook(expand('<amatch>'))
        autocmd BufDelete * call s:LoclistFollowToggle(-1)
    endif
augroup END

command! -bar LoclistFollowToggle call s:LoclistFollowToggle()
command! -bar LoclistFollowGlobalToggle call s:LoclistFollowGlobalToggle()
