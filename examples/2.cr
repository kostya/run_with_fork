require "../src/run_with_fork"
require "digest/md5"

t = Time.now

res = Channel(String).new

times = (ARGV[0]? || 100).to_i
count = (ARGV[1]? || 10000).to_i
use_fork = (ARGV[2]? == "1")

puts "use #{use_fork ? "fork" : "fiber"}"

def operation(count, data)
  s = ""
  count.times do
    s = Digest::MD5.hexdigest("#{data} bla #{s}")
  end
  "done #{data} #{s}"
end

times.times do |i|
  spawn do
    if use_fork
      pid, r = Process.run_with_fork(run_hooks: true) do |w|
        w.puts operation(count, i)
      end

      s = r.gets
      r.close
      res.send s.not_nil!
    else
      res.send operation(count, i)
    end
  end
end

times.times do
  p res.receive
end

p Time.now - t
