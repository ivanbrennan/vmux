module Tmux
  def spawn_new_session(session_name)
    sidestep_nested_session_restriction do
      run_silent_command("new-session -d -s #{session_name}")
    end
  end

  def kill_session(session_name)
    run_silent_command("kill-session -t #{session_name}")
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

