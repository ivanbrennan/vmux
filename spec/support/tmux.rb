module Tmux
  def new_session(session_name)
    sidestep_nested_session_restriction do
      run_silent_command("new-session -d -s #{session_name}")
    end
  end

  def list_sessions
    run_silent_command("list-sessions -F '\#{session_name}'").split("\n")
  end

  def kill_session(session_name)
    run_silent_command("kill-session -t #{session_name}")
  end

  def new_window(session_name, window_index)
    run_silent_command("new-window -t #{session_name}:#{window_index}")
  end

  def window_index(session_name)
    run_silent_command("display-message -t #{session_name} -p '\#{window_index}'")
  end

  def split_window(session_name, window_index, orientation='v')
    command = "split-window -#{orientation} -t #{session_name}:#{window_index}"
    run_silent_command(command)
  end

  def pane_index(session_name, window_index)
    command = "display-message -p -t #{session_name}:#{window_index} '\#{pane_index}'"
    run_silent_command(command)
  end

  def select_pane(session_name, window_index, pane_index)
    command = "select-pane -t #{session_name}:#{window_index}.#{pane_index}"
    run_silent_command(command)
  end

  def capture_pane(target_pane)
    run_silent_command("capture-pane -p -t #{target_pane}")
  end

  def kill_server
    run_silent_command("kill-server")
  end

  private

  def run_silent_command(command)
    output = %x(tmux #{command} 2>&1).chomp
    $?.success? ? output : raise(output)
  end

  def sidestep_nested_session_restriction
    if ENV.has_key?('TMUX')
      ENV['TMUX_OLD'] = ENV.delete('TMUX')
    end
    yield
    if ENV.has_key?('TMUX_OLD')
      ENV['TMUX'] = ENV.delete('TMUX_OLD')
    end
  end
end

