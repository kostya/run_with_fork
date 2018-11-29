require "./run_with_fork/*"

module RunWithFork
end

class Process
  def self.run_with_fork(disable_gc = false, silent = false, run_hooks = true)
    r, w = IO.pipe(write_blocking: true)
    process = fork do
      GC.disable if disable_gc
      w.reopen(w)
      yield(w)
      w.flush
    end
    w.try(&.close) rescue nil
    {process, r}
  end
end
