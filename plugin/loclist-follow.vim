
" defaults
let s:loclist_follow_modes = 'ni'
let s:loclist_follow_target = [0, 'nearest']
" mode event map
let s:loclist_follow_hook_events = {'n': 'CursorMoved', 'i': 'CursorMovedI'}
let s:loclist_follow_target_types = {0: [0, 'nearest'], 1: [1, 'previous'], 2: [2, 'next'], 3: [3, 'towards'], 4: [4, 'away']}

" jump to nearest item in the location list based on current line
function! s:LoclistFollow(scope, bnr) abort
    " short-circuits
    if exists('b:loclist_follow') && !b:loclist_follow
        return
    endif
    if exists('b:loclist_follow_file') && b:loclist_follow_file != fnamemodify(bufname(''), ':p')
        return
    endif
    let ll = []
    let ll_pos = 1
    let ll_scope = a:scope ==? 'global' ? getqflist() : getloclist('')
    for v in ll_scope
        if v.bufnr == a:bnr
            call add(ll, [ll_pos, v])
        endif
        let ll_pos += 1
    endfor
    let l_ll = len(ll)
    if l_ll == 0
        return
    endif
    let pos = getpos('.')
    let ln = pos[1]
    let col = pos[2]

    " determine current item based of target type (default: nearest), assume
    " last as optimum start, correct and account for multiple items per line

    let target = s:loclist_follow_target[1]
    if target ==? 'towards' || target ==? 'away'
        if exists('b:loclist_follow_cursor')
            if ln > b:loclist_follow_cursor[1] ||
               \ (ln == b:loclist_follow_cursor[1] &&
               \  col > b:loclist_follow_cursor[2])
                let target = target ==? 'towards' ? 'next' : 'previous'
            else
                let target = target ==? 'towards' ? 'previous' : 'next'
            endif
        else
            let target = 'nearest'
        end
        let b:loclist_follow_cursor = pos
    endif
    let idx = 0

    " line
    if exists('b:loclist_follow_pos')
        let idx = min([l_ll - 1, b:loclist_follow_pos - 1])
    endif
    while get(ll, idx)[1].lnum >= ln && idx > 0
        let idx -= 1
    endwhile
    while get(ll, idx)[1].lnum < ln && idx < l_ll - 1
        let idx += 1
    endwhile

    " column
    if get(ll, idx)[1].lnum == ln
        while idx + 1 < l_ll && get(ll, idx + 1)[1].lnum == ln
            if col > get(ll, idx + 1)[1].col
                let idx += 1
            elseif col == get(ll, idx)[1].col && col == get(ll, idx + 1)[1].col
                break
            elseif abs(get(ll, idx + 1)[1].col - col) < abs(get(ll, idx)[1].col - col)
                let idx += 1
            else
                break
            endif
        endwhile
        if target ==? 'previous' && col < get(ll, idx)[1].col
            let idx = max([idx - 1, 0])
        elseif target ==? 'next' && col > get(ll, idx)[1].col
            let idx = min([idx + 1, l_ll])
        endif
    endif

    let jump = 0
    if target ==? 'nearest'
        let jump = abs(get(ll, max([idx - 1, 0]))[1].lnum - ln) < abs(get(ll,idx)[1].lnum - ln) ? -1 : 0
    elseif target ==? 'previous' && get(ll, idx)[1].lnum > ln
        let jump = -1
    endif
    let idx_next = min([max([idx + jump, 0]), l_ll - 1])

    " set
    if idx_next < 0 || (exists('b:loclist_follow_pos') && b:loclist_follow_pos == idx_next + 1)
        return
    endif
    let ll_pos = ll[idx_next][0]
    let b:loclist_follow_pos = ll_pos
    exe (a:scope ==? 'global' ? 'cc' : 'll') b:loclist_follow_pos
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
            redraw | echo('ignoring invalid mode type ''' . c . '''')
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
            execute 'autocmd loclist_follow' ev '<buffer=' . bufnr('') . '> call s:LoclistFollow("local", ' . bufnr('') . ')'
            execute 'autocmd loclist_follow' ev '<buffer=' . bufnr('') . '> call s:LoclistFollow("global", ' . bufnr('') . ')'
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
    let touched = filter(getbufinfo(), 'exists("v:val.variables.loclist_follow")')
    let bv = (gv == 0 ? -1 : 1)
    for b in touched
        if b.variables.loclist_follow != 0
            call setbufvar(b.bufnr, 'loclist_follow', bv)
            if bv == 1
                "add hook to previously globally toggled buffer
                for ev in events
                    execute 'autocmd!' ev '<buffer=' . b.bufnr . '> call s:LoclistFollow("local", ' . b.bufnr . ')'
                    execute 'autocmd!' ev '<buffer=' . b.bufnr . '> call s:LoclistFollow("global", ' . b.bufnr . ')'
                endfor
            endif
        endif
    endfor
endfunction

function! s:LoclistFollowTarget()
    if s:loclist_follow_target[1] != g:loclist_follow_target
        let match = filter(values(s:loclist_follow_target_types), 'v:val[1] == g:loclist_follow_target')
        if len(match) == 0
            redraw | echo('invalid target type ''' . g:loclist_follow_target . '''')
            return 1
        else
            let s:loclist_follow_target = match[0]
        endif
    endif
    return 0
endfunction

function! s:LoclistFollowTargetToggle()
    if !exists('g:loclist_follow')
        return
    endif

    let valid = 1
    if exists('g:loclist_follow_target')
        " validate target
        let valid = !s:LoclistFollowTarget()
        if valid == 0
            " prefer failure
            return
        endif
    endif

    " cycle / toggle
    let s:loclist_follow_target = s:loclist_follow_target_types[(s:loclist_follow_target[0] + 1) % len(s:loclist_follow_target_types)]
    redraw | echo('loclist-follow-target toggled: ''' . s:loclist_follow_target[1] . '''')
    if exists('g:loclist_follow_target') && valid == 1
        " sync global
        let g:loclist_follow_target = s:loclist_follow_target[1]
    endif
endfunction

function! s:BufReadPostHook(file_) abort
    if !exists('g:loclist_follow')
        return
    endif
    if getwininfo(win_getid())[0].quickfix == 1
        return
    endif

    if g:loclist_follow == 1
        if exists('g:loclist_follow_target')
            " validate target
            call s:LoclistFollowTarget()
        endif
        if !exists('b:loclist_follow')
            " enable loclist-follow
            call s:LoclistFollowToggle(1)
        endif
        if exists('b:loclist_follow_file') && b:loclist_follow_file != a:file_
            " reset
            unlet! b:loclist_follow_pos
            unlet! b:loclist_follow_cursor
        endif
        let b:loclist_follow_file = a:file_
    else
        call s:LoclistFollowToggle(-1)
        unlet! b:loclist_follow
        unlet! b:loclist_follow_file
        unlet! b:loclist_follow_pos
        unlet! b:loclist_follow_cursor
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
command! -bar LoclistFollowTargetToggle call s:LoclistFollowTargetToggle()
