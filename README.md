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

Inspiration from vim-tmux-runner and tslime

API commands:

 - :VmuxPrimary
 - :VmuxSecondary
 - :VmuxSend
 - :VmuxPaste
