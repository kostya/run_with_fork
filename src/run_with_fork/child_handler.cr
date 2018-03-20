# :nodoc:
module Crystal::SignalChildHandler
  # Process#wait will block until the sub-process has terminated. On POSIX
  # systems, the SIGCHLD signal is triggered. We thus always trap SIGCHLD then
  # reap/memorize terminated child processes and eventually notify
  # Process#wait through a channel, that may be created before or after the
  # child process exited.

  @@pending = {} of LibC::PidT => Int32
  @@waiting = {} of LibC::PidT => Channel::Buffered(Int32)
  @@mutex = Mutex.new

  def self.wait(pid : LibC::PidT) : Channel::Buffered(Int32)
    channel = Channel::Buffered(Int32).new(1)

    @@mutex.lock
    if exit_code = @@pending.delete(pid)
      @@mutex.unlock
      channel.send(exit_code)
      channel.close
    else
      @@waiting[pid] = channel
      @@mutex.unlock
    end

    channel
  end

  def self.call : Nil
    loop do
      pid = LibC.waitpid(-1, out exit_code, LibC::WNOHANG)

      case pid
      when 0
        return
      when -1
        return if Errno.value == Errno::ECHILD
        raise Errno.new("waitpid")
      end

      @@mutex.lock
      if channel = @@waiting.delete(pid)
        @@mutex.unlock
        channel.send(exit_code)
        channel.close
      else
        @@pending[pid] = exit_code
        @@mutex.unlock
      end
    end
  end

  def self.after_fork
    @@pending.clear
    @@waiting.each_value(&.close)
    @@waiting.clear
  end
end
