let s:session_pattern = '\v^[-_[:alnum:]]+'
let s:window_pattern  = s:session_pattern . ':\zs\d+'
let s:pane_pattern    = s:session_pattern . ':\d+\.\zs\d+'

func! vmux#set_target(rank)
  let prompt = '"Enter ' . a:rank . ' target: "'
  let target = 'g:vmux_' . a:rank
  execute 'let '.target.' = '.'input('.prompt.', '.target.', "custom,Targets")'
endf

func! Targets(A, L, P)
  let session = matchstr(a:L, s:session_pattern . '\ze:')
  let window  = matchstr(a:L, s:window_pattern . '\ze\.')
  let pane    = matchstr(a:L, s:pane_pattern)

  if session == ''
    return vmux#sessions()
  elseif window == ''
    return vmux#windows(session)
  elseif pane == ''
    return vmux#panes(session, window)
  endif
endf

func! vmux#sessions()
  let sessions = system("tmux list-sessions -F '#{session_name}'")
  return v:shell_error ? '' : sessions
endf

func! vmux#windows(session)
  let format = "'#{session_name}:#{window_index}'"
  return system('tmux list-windows -t' . a:session . ' -F' . format)
endf

func! vmux#panes(session, window)
  let target = a:session . ':' . a:window
  let format = "'#{session_name}:#{window_index}.#{pane_index}'"
  return system('tmux list-panes -t' . target . ' -F' . format)
endf

func! vmux#open_target(rank)
  let session = vmux#targeted_element(s:session_pattern, a:rank)

  if session != ''
    let window = vmux#targeted_element(s:window_pattern, a:rank)
    if window != ''
      call vmux#run_shell_cmd('tmux select-window -t ' . session . ':' . window)
    else
      let window = vmux#active_index(session, 'window')
      execute 'let g:vmux_' . a:rank . ' .= ":' . window . '"'
    endif

    let pane = vmux#targeted_element(s:pane_pattern, a:rank)
    if pane == ''
      let pane = vmux#active_index(session.':'.window, 'pane')
      execute 'let g:vmux_' . a:rank . ' .= ".' . pane . '"'
    endif
  else
    call vmux#set_target(a:rank)
    call vmux#open_target(a:rank)
  endif
endf

func! vmux#targeted_element(element_pattern, rank)
  execute 'let target = g:vmux_' . a:rank
  return matchstr(target, a:element_pattern)
endf

func! vmux#active_index(scope, element)
  let opts = '-p -t '.a:scope.' "#{'.a:element.'_index}"'
  return matchstr(system('tmux display-message '.opts), '\d\+')
endf

func! vmux#run_shell_cmd(command)
  let out = system(a:command)
  if v:shell_error | call vmux#echo_error(out) | endif
endf

func! vmux#echo_error(message)
  let full_message = 'vmux: ' . matchstr(a:message, '\p\+')
  echohl ErrorMsg | echom full_message | echohl None
  let v:errmsg = full_message
endf

func! vmux#send_keys(text, rank)
  execute 'let target = g:vmux_' . a:rank
  call vmux#run_shell_cmd('tmux send-keys -t' . target . ' ' . a:text . ' Enter')
endf
