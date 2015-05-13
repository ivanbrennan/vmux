" vmux.vim - plug Vim into tmux

if exists("g:loaded_vmux") || v:version < 700 || &cp
  finish
endif
let g:loaded_vmux = 1

let s:session_pattern = '\v^[-_[:alnum:]]+'
let s:window_pattern  = s:session_pattern . ':\zs\d+'
let s:pane_pattern    = s:session_pattern . ':\d+\.\zs\d+'

function! s:InitVar(variable_name)
  if ! exists(a:variable_name)
    execute 'let ' . a:variable_name . ' = ""'
  endif
endfunction

function! s:SetTarget(rank)
  let prompt = '"Enter ' . a:rank . ' target: "'
  let target = 'g:vmux_' . a:rank
  execute 'let '.target.' = '.'input('.prompt.', '.target.', "custom,Targets")'
endfunction

function! Targets(A, L, P)
  let session = matchstr(a:L, s:session_pattern . '\ze:')
  let window  = matchstr(a:L, s:window_pattern . '\ze\.')
  let pane    = matchstr(a:L, s:pane_pattern)

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
  let session = s:TargetedElement(s:session_pattern, a:rank)

  if session != ''
    let window = s:TargetedElement(s:window_pattern, a:rank)
    if window != ''
      call s:RunShellCmd('tmux select-window -t ' . session . ':' . window)
    else
      let window = s:ActiveIndex(session, 'window')
      execute 'let g:vmux_' . a:rank . ' .= ":' . window . '"'
    endif

    let pane = s:TargetedElement(s:pane_pattern, a:rank)
    if pane == ''
      let pane = s:ActiveIndex(session.':'.window, 'pane')
      execute 'let g:vmux_' . a:rank . ' .= ".' . pane . '"'
    endif
  else
    call s:SetTarget(a:rank)
    call s:OpenTarget(a:rank)
  endif
endfunction

function! s:TargetedElement(element_pattern, rank)
  execute 'let target = g:vmux_' . a:rank
  return matchstr(target, a:element_pattern)
endfunction

function! s:ActiveIndex(scope, element)
  let opts = '-p -t '.a:scope.' "#{'.a:element.'_index}"'
  return matchstr(system('tmux display-message '.opts), '\d\+')
endfunction

function! s:RunShellCmd(command)
  let out = system(a:command)
  if v:shell_error | call s:EchoError(out) | endif
endfunction

function! s:EchoError(message)
  let full_message = 'vmux: ' . matchstr(a:message, '\p\+')
  echohl ErrorMsg | echom full_message | echohl None
  let v:errmsg = full_message
endfunction

function! s:SendKeys(text, rank)
  execute 'let target = g:vmux_' . a:rank
  call s:RunShellCmd('tmux send-keys -t' . target . ' ' . a:text . ' Enter')
endfunction

call s:InitVar('g:vmux_primary')
call s:InitVar('g:vmux_secondary')
call s:InitVar('g:vmux_auto_spawn')

command!          VmuxPrimary       call s:SetTarget('primary')
command!          VmuxSecondary     call s:SetTarget('secondary')
command!          VmuxOpenPrimary   call s:OpenTarget('primary')
command!          VmuxOpenSecondary call s:OpenTarget('secondary')
command! -nargs=1 VmuxSendPrimary   call s:SendKeys(<f-args>, 'primary')
command! -nargs=1 VmuxSendSecondary call s:SendKeys(<f-args>, 'secondary')
