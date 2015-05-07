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
  let format = "'#{session_name}'"
  return s:SendTmuxCommand('list-sessions', '', format)
endfunction

function! s:TmuxWindows(session)
  let target = a:session
  let format = "'#{session_name}:#{window_index}'"
  return s:SendTmuxCommand('list-windows', target, format)
endfunction

function! s:TmuxPanes(session, window)
  let target = a:session . ":" . a:window
  let format = "'#{session_name}:#{window_index}.#{pane_index}'"
  return s:SendTmuxCommand('list-panes', target, format)
endfunction

function! s:SendTmuxCommand(cmd, ...)
  let a1 = exists('a:1') && a:1 != ''
  let target = a1 ? ' -t ' . a:1 : ''

  let a2 = exists('a:2') && a:2 != ''
  let format = a2 ? ' -F ' . a:2 : ''

  return system('tmux ' . a:cmd . target . format)
endfunction

call s:InitVar('g:vmux_primary')
call s:InitVar('g:vmux_secondary')

command! VmuxPrimary   call s:SetTarget('primary')
command! VmuxSecondary call s:SetTarget('secondary')

