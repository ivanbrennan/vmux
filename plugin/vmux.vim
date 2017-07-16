" vmux.vim - plug Vim into tmux

if exists("g:loaded_vmux") || v:version < 700 || &cp
  finish
endif
let g:loaded_vmux = 1

let g:vmux_primary = ''
let g:vmux_secondary = ''
let g:vmux_auto_spawn = ''

command!          VmuxPrimary       call vmux#set_target('primary')
command!          VmuxSecondary     call vmux#set_target('secondary')
command!          VmuxOpenPrimary   call vmux#open_target('primary')
command!          VmuxOpenSecondary call vmux#open_target('secondary')
command! -nargs=1 VmuxSendPrimary   call vmux#send_keys(<f-args>, 'primary')
command! -nargs=1 VmuxSendSecondary call vmux#send_keys(<f-args>, 'secondary')
