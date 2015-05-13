# vmux.vim

Plug Vim into tmux.

Initial motivation:

Send vim-spec-runner commands to another tmux session.

```
function! Spatch()
  let sessions = system("tmux list-sessions -F '#{session_name}'")
  let target   = input('Enter target: ')
  let target_session = matchstr(target, '[[:alnum:]_-]\+')

  if (sessions =~ target_session) && (target_session != '')
    let g:spec_runner_dispatcher = "call system(\"tmux send -t "
          \                        . target .
          \                        " C-L '{command}' ENTER\")"
  else
    let g:spec_runner_dispatcher = "VtrSendCommand! {command}"
  endif
endfunction
```

Concept:

Maintain a pair of tmux targets (e.g. one for running specs, another
for pasting to a repl). Use compound tab-completion to set a target
\<session>:\<window>.\<pane> at a single prompt. Provide basic commands to
direct a command at a target.

- global-variables:
  * g:vmux_primary
  * g:vmux_secondary
- Tab completion: given a running session 'my-session' with window 7
                  named 'tests', set the target to my-session:7.1

  Enter target:
  'my-se<Tab>'              -> 'my-session'
  'my-session:tes<Tab>'     -> 'my-session:7'
  'my-session:7.<Tab><Tab>' -> 'my-session:7.1'

  'my-se<Tab>:tes<Tab>.<Tab><Tab>' -> 'my-session:7.1'

  Completing a window name inserts the number of the first matching window.
  If multiple windows match, cycle through them.

  Omitting window or window-and-pane allows the default tmux behavior,
  targetting the active window and/or pane in the targeted session.

  If window and/or pane are specified, tell the tmux session to select that
  window and/or pane before running further commands.

- Allow for automatically opening a new pane or window upon trigger
  This might be an alternative to targeting the current window/pane.
  If only session is specified, tests pop open a new window in the
  specified session; if only session:window is specified, tests pop open
  a new pane in the specified window.

- g:vmux_auto_spawn option
- 0 : If target doesn't specify a window and/or pane, commands to go to
  whichever is active.
- 1 : If target doesn't specify a window, create one named "vmux" and
  adjust target to point at "\<session>:vmux.0". If target specifies
  window but no pane, split the window's currently active pane and adjust
  target to point at the new pane.

- Build checks to:
  * avoid stealing focus from vim (hiding vim window if running inside tmux)
  * avoid sending tmux commands to pane vim is running in
  * reselect pane that was active before splitting window
Inspiration from vim-tmux-runner and tslime

API commands:

 - :VmuxPrimary
 - :VmuxSecondary
 - :VmuxSend
 - :VmuxPaste
