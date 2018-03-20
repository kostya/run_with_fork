require "./run_with_fork/*"

module RunWithFork
end

class Process
  def self.run_with_fork(disable_gc = false, silent = false, run_hooks = false)
    r, w = IO.pipe(write_blocking: true)
    pid = Process.fork_internal(run_hooks: run_hooks) do
      begin
        GC.disable if disable_gc
        w.reopen(w)
        yield(w)
      rescue ex
        ex.inspect_with_backtrace(STDERR) unless silent
      ensure
        LibC._exit 127
      end
    end

    waitpid = Crystal::SignalChildHandler.wait(pid)

    w.try &.close
    {pid, r}
  end
end
