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
  let prompt   = '"Enter ' . a:rank . ' target: "'
  let default  = 'g:vmux_' . a:rank
  let complete = '"custom,Targets"'

  execute 'let g:vmux_'.a:rank.' = '.'input('.prompt.', '.default.', '.complete.')'
endfunction

function! Targets(A, L, P)
  let session = matchstr(a:L, '\v^\zs[-_[:alnum:]]+\ze:')
  let window  = matchstr(a:L, '\v^[-_[:alnum:]]+:\zs\d+\ze\.')
  let pane    = matchstr(a:L, '\v^[-_[:alnum:]]+:\d+\.\zs\d+')

  if session == ''
    return s:Sessions()
  elseif window == ''
    return s:Windows(session)
  elseif pane == ''
    return s:Panes(session, window)
  endif
endfunction

function! s:Sessions()
  return system("tmux list-sessions -F '#{session_name}'")
endfunction

function! s:Windows(session)
  let format = "'#{session_name}:#{window_index}'"
  return system('tmux list-windows -t' . a:session . ' -F' . format)
endfunction

function! s:Panes(session, window)
  let target = a:session . ':' . a:window
  let format = "'#{session_name}:#{window_index}.#{pane_index}'"
  return system('tmux list-panes -t' . target . ' -F' . format)
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

