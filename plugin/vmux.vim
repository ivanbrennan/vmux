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
  let sessions = system("tmux list-sessions -F '#{session_name}'")
  return v:shell_error ? '' : sessions
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

function! s:OpenTarget(rank)
  execute "let session = matchstr(g:vmux_" . a:rank . ", '\\v^\\zs[-_[:alnum:]]+')"

  if session == ''
    call s:SetTarget(a:rank)    " prompt for target
    return s:OpenTarget(a:rank) " and try again
  endif

  execute "let window = matchstr(g:vmux_" . a:rank . ", '\\v^[-_[:alnum:]]+:\\zs\\d+')"

  if window == ''
    " update target to use active window
    let window_query = 'tmux display-message -p -t ' . session . " '#{window_index}'"
    let window = matchstr(system(window_query), '\d\+')
    execute 'let g:vmux_' . a:rank . ' .= ":' . window . '"'
  else
    " select targeted window
    call s:SystemCall('tmux select-window -t ' . session . ':' . window)
  endif

  execute "let pane = matchstr(g:vmux_" . a:rank . ", '\\v^[-_[:alnum:]]+:\\d+\\.\\zs\\d+')"

  if pane == ''
    " update target to use active pane
    let pane_query = 'tmux display-message -p -t ' . session . ':' . window . " '#{pane_index}'"
    let pane = matchstr(system(pane_query), '\d\+')
    execute 'let g:vmux_' . a:rank . ' .= ".' . pane . '"'
  else
    " select targeted pane
    call s:SystemCall('tmux select-pane -t ' . session . ':' . window . '.' . pane)
  endif
endfunction

function! s:SystemCall(command)
  let out = system(a:command)
  if v:shell_error | call s:EchoError(out) | endif
endfunction

function! s:EchoError(message)
  let full_message = 'vmux: ' . matchstr(a:message, '\p\+')
  echohl ErrorMsg | echom full_message | echohl None
  let v:errmsg = full_message
endfunction

function! s:SendKeys(rank, text)
  execute 'let target = g:vmux_' . a:rank
  call s:SystemCall('tmux send-keys -t' . target . ' ' . a:text . ' Enter')
endfunction

call s:InitVar('g:vmux_primary')
call s:InitVar('g:vmux_secondary')
call s:InitVar('g:vmux_auto_spawn')

command!          VmuxPrimary       call s:SetTarget('primary')
command!          VmuxSecondary     call s:SetTarget('secondary')
command!          VmuxOpenPrimary   call s:OpenTarget('primary')
command!          VmuxOpenSecondary call s:OpenTarget('secondary')
command! -nargs=1 VmuxSendPrimary   call s:SendKeys('primary', <f-args>)
command! -nargs=1 VmuxSendSecondary call s:SendKeys('secondary', <f-args>)
