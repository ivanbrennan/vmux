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

call s:InitVar('g:vmux_primary')
call s:InitVar('g:vmux_secondary')

function! s:SetTarget(rank)
  call s:InitVar('g:vmux_' . a:rank)

  let prompt   = '"Enter ' . a:rank . ' target: "'
  let default  = 'g:vmux_' . a:rank
  let complete = '"custom,ListTargets"'

  execute 'let g:vmux_' . a:rank . ' = ' . 'input(' . prompt . ',' . default . ',' . complete . ')'
endfunction

function! ListTargets(A, L, P)
  let chars = '[-_[:alnum:]]\+'

  let session = matchstr(a:L, '^\zs' . chars . '\ze:')
  let window  = matchstr(a:L, '^'    . chars .    ':\zs' . chars . '\ze\.')
  let pane    = matchstr(a:L, '^'    . chars .    ':'    . chars .    '\.\zs\d\+')

  if session == ''
    return s:TmuxSessions()
  elseif window == ''
    return s:TmuxWindows(session)
  elseif pane == ''
    return s:TmuxPanes(session, window)
  endif
endfunction

function! s:TmuxSessions()
  return system("tmux list-sessions -F '#{session_name}'")
endfunction

function! s:TmuxWindows(session)
  return system("tmux list-windows -t " . a:session . " -F '#{session_name}:#{window_index}'")
endfunction

function! s:TmuxPanes(session, window)
  return system("tmux list-panes -t " . a:session . ":" . a:window . " -F '#{session_name}:#{window_index}.#{pane_index}'")
endfunction

command! VmuxPrimary   call s:SetTarget('primary')
command! VmuxSecondary call s:SetTarget('secondary')

