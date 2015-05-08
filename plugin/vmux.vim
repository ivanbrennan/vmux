" vmux.vim - plug Vim into tmux

if exists("g:loaded_vmux") || v:version < 700 || &cp
  finish
endif
let g:loaded_vmux = 1

function! s:InitVar(variable_name)
  if ! exists(a:variable_name)
    execute 'let ' . a:variable_name . ' = ""'
  endif
endfunction

function! s:SetTarget(rank)
  call s:InitVar('g:vmux_' . a:rank)

  let prompt   = '"Enter ' . a:rank . ' target: "'
  let default  = 'g:vmux_' . a:rank
  let complete = '"custom,ListTargets"'

  execute 'let g:vmux_'.a:rank.' = '.'input('.prompt.', '.default.', '.complete.')'
endfunction

function! ListTargets(A, L, P)
  let session_pattern = '\v^\zs[-_[:alnum:]]+\ze:'
  let window_pattern  = '\v^[-_[:alnum:]]+:\zs\d+\ze\.'
  let pane_pattern    = '\v^[-_[:alnum:]]+:\d+\.\zs\d+'

  let session = matchstr(a:L, session_pattern)
  let window  = matchstr(a:L, window_pattern)
  let pane    = matchstr(a:L, pane_pattern)

  if session == ''
    return s:TmuxSessions()
  elseif window == ''
    return s:TmuxWindows(session)
  elseif pane == ''
    return s:TmuxPanes(session, window)
  endif
endfunction

function! s:TmuxSessions()
  return s:TmuxList('sessions', '', "'#{session_name}'")
endfunction

function! s:TmuxWindows(session)
  let format = "'#{session_name}:#{window_index}'"
  return s:TmuxList('windows', a:session, format)
endfunction

function! s:TmuxPanes(session, window)
  let format = "'#{session_name}:#{window_index}.#{pane_index}'"
  return s:TmuxList('panes', a:session.':'.a:window, format)
endfunction

function! s:TmuxList(type, target, format)
  let target = a:target == '' ? '' : ' -t '.a:target
  let format = a:format == '' ? '' : ' -F '.a:format
  return system('tmux list-' . a:type . target . format)
endfunction

function! s:RevealTarget(rank)
  execute 'let target = g:vmux_' . a:rank
  let session_window = matchstr(target, '\v^\zs[-_[:alnum:]]+:?\d*\ze')
  call system('tmux select-window -t ' . session_window)
endfunction

call s:InitVar('g:vmux_primary')
call s:InitVar('g:vmux_secondary')

command! VmuxPrimary         call s:SetTarget('primary')
command! VmuxSecondary       call s:SetTarget('secondary')
command! VmuxRevealPrimary   call s:RevealTarget('primary')
command! VmuxRevealSecondary call s:RevealTarget('secondary')

