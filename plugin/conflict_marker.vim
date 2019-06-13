if exists('g:loaded_conflict_marker')
    finish
endif

let s:save_cpo = &cpo
set cpo&vim

function! s:var(name, default)
    let g:conflict_marker_{a:name} = get(g:, 'conflict_marker_'.a:name, a:default)
endfunction

call s:var('highlight_group', 'Error')
call s:var('begin', '^<<<<<<< \@=')
call s:var('separator', '^=======$')
call s:var('end', '^>>>>>>> \@=')
call s:var('enable_mappings', 1)
call s:var('enable_hooks', 1)
call s:var('enable_highlight', 1)
call s:var('enable_matchit', 1)

command! -nargs=0 ConflictMarkerThemselves     call conflict_marker#themselves()
command! -nargs=0 ConflictMarkerOurselves      call conflict_marker#ourselves()
command! -nargs=0 ConflictMarkerBoth           call conflict_marker#compromise()
command! -nargs=0 ConflictMarkerNone           call conflict_marker#down_together()
command! -nargs=0 -bang ConflictMarkerNextHunk call conflict_marker#next_conflict(<bang>0)
command! -nargs=0 -bang ConflictMarkerPrevHunk call conflict_marker#previous_conflict(<bang>0)

nnoremap <silent><Plug>(conflict-marker-themselves) :<C-u>ConflictMarkerThemselves<CR>
nnoremap <silent><Plug>(conflict-marker-ourselves)  :<C-u>ConflictMarkerOurselves<CR>
nnoremap <silent><Plug>(conflict-marker-both)       :<C-u>ConflictMarkerBoth<CR>
nnoremap <silent><Plug>(conflict-marker-none)       :<C-u>ConflictMarkerNone<CR>
nnoremap <silent><Plug>(conflict-marker-next-hunk)  :<C-u>ConflictMarkerNextHunk<CR>
nnoremap <silent><Plug>(conflict-marker-prev-hunk)  :<C-u>ConflictMarkerPrevHunk<CR>

function! s:execute_hooks()
    if exists('g:conflict_marker_hooks') && has_key(g:conflict_marker_hooks, 'on_detected')
        if type(g:conflict_marker_hooks.on_detected) == type('')
            call call(function(g:conflict_marker_hooks.on_detected), [])
        else
            call call(g:conflict_marker_hooks.on_detected, [], {})
        endif
    endif
endfunction

function! s:set_conflict_marker_to_match_words()
    if ! exists('g:loaded_matchit')
        runtime macros/matchit.vim
        if ! exists('g:loaded_matchit')
            " matchit.vim doesn't exists. remove autocmd
            let g:conflict_marker_enable_matchit = 0
        endif
    endif

    if exists('b:conflict_marker_match_words_loaded')
        return
    endif

    let b:match_words = get(b:, 'match_words', '')
                \       . printf(',%s:%s:%s',
                \                g:conflict_marker_begin,
                \                g:conflict_marker_separator,
                \                g:conflict_marker_end)
    let b:conflict_marker_match_words_loaded = 1
endfunction

function! s:init_mode()
    let mappings = []
    call add(mappings, mode#mapping#create('n', 0, 1, ']x', '<Plug>(conflict-marker-next-hunk)'))
    call add(mappings, mode#mapping#create('n', 0, 1, '[x', '<Plug>(conflict-marker-prev-hunk)'))
    call add(mappings, mode#mapping#create('n', 0, 1, 'ct', '<Plug>(conflict-marker-themselves)'))
    call add(mappings, mode#mapping#create('n', 0, 1, 'co', '<Plug>(conflict-marker-ourselves)'))
    call add(mappings, mode#mapping#create('n', 0, 1, 'cn', '<Plug>(conflict-marker-none)'))
    call add(mappings, mode#mapping#create('n', 0, 1, 'cb', '<Plug>(conflict-marker-both)'))

    try
        call mode#add('conflict_marker', 'C', mappings)
    catch /^E117
        echom 'Please install https://github.com/tenfyzhong/mode.vim first'
        return
    endtry
endfunction

let s:inited = 0
function! s:enable()
    if !s:inited
        call s:init_mode()
        let s:inited = 1
    endif
    call mode#enable('conflict_marker')
endfunction

function! s:disable()
    call mode#disable('conflict_marker')
endfunction

function! s:on_detected()
    echom "It seems some conflict in the file, please resolve it."
endfunction

if g:conflict_marker_enable_highlight
    execute printf('syntax match ConflictMarker containedin=ALL /\%(%s\|%s\|%s\)/',
            \      g:conflict_marker_begin,
            \      g:conflict_marker_separator,
            \      g:conflict_marker_end)
    execute 'highlight link ConflictMarker '.g:conflict_marker_highlight_group
endif

if g:conflict_marker_enable_matchit
    call s:set_conflict_marker_to_match_words()
endif

augroup ConflictMarkerDetect
    autocmd!
    autocmd BufReadPost * if conflict_marker#detect#markers() | call s:on_detected() | endif
augroup END

if g:conflict_marker_enable_highlight
    execute 'highlight link ConflictMarker '.g:conflict_marker_highlight_group
endif

command! ConflictMarkerEnable call <SID>enable()
command! ConflictMarkerDisable call <SID>disable()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_conflict_marker = 1
