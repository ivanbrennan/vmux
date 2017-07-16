let s:session_pattern = '\v^[-_[:alnum:]]+'
let s:window_pattern  = s:session_pattern . ':\zs\d+'
let s:pane_pattern    = s:session_pattern . ':\d+\.\zs\d+'

func! vmux#set_target(rank)
  let prompt = '"Enter ' . a:rank . ' target: "'
  let target = 'g:vmux_' . a:rank
  execute 'let' target '= input(' prompt ',' target ', "custom,s:targets")'
endf

func! vmux#open_target(rank)
  let session = s:targeted_element(s:session_pattern, a:rank)

  if session != ''
    let window = s:targeted_element(s:window_pattern, a:rank)
    if window != ''
      call s:run_shell_cmd('tmux select-window -t ' . session . ':' . window)
    else
      let window = s:active_index(session, 'window')
      execute 'let g:vmux_' . a:rank . ' .= ":' . window . '"'
    endif

    let pane = s:targeted_element(s:pane_pattern, a:rank)
    if pane == ''
      let pane = s:active_index(session.':'.window, 'pane')
      execute 'let g:vmux_' . a:rank . ' .= ".' . pane . '"'
    endif
  else
    call vmux#set_target(a:rank)
    call vmux#open_target(a:rank)
  endif
endf

func! vmux#send_keys(text, rank)
  execute 'let target = g:vmux_' . a:rank
  call s:run_shell_cmd('tmux send-keys -t' . target . ' ' . a:text . ' Enter')
endf

func! s:targets(A, L, P)
  let session = matchstr(a:L, s:session_pattern . '\ze:')
  let window  = matchstr(a:L, s:window_pattern . '\ze\.')
  let pane    = matchstr(a:L, s:pane_pattern)

  if session == ''
    return s:sessions()
  elseif window == ''
    return s:windows(session)
  elseif pane == ''
    return s:panes(session, window)
  endif
endf

func! s:sessions()
  let sessions = system("tmux list-sessions -F '#{session_name}'")
  return v:shell_error ? '' : sessions
endf

func! s:windows(session)
  let format = "'#{session_name}:#{window_index}'"
  return system('tmux list-windows -t' . a:session . ' -F' . format)
endf

func! s:panes(session, window)
  let target = a:session . ':' . a:window
  let format = "'#{session_name}:#{window_index}.#{pane_index}'"
  return system('tmux list-panes -t' . target . ' -F' . format)
endf

func! s:targeted_element(element_pattern, rank)
  execute 'let target = g:vmux_' . a:rank
  return matchstr(target, a:element_pattern)
endf

func! s:active_index(scope, element)
  let opts = '-p -t '.a:scope.' "#{'.a:element.'_index}"'
  return matchstr(system('tmux display-message '.opts), '\d\+')
endf

func! s:run_shell_cmd(command)
  let out = system(a:command)
  if v:shell_error | call s:echo_error(out) | endif
endf

func! s:echo_error(message)
  let full_message = 'vmux: ' . matchstr(a:message, '\p\+')
  echohl ErrorMsg | echom full_message | echohl None
  let v:errmsg = full_message
endf
