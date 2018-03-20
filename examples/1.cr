require "../src/run_with_fork"
require "digest/md5"

def heavy_operation(str)
  1000.times { str = Digest::MD5.hexdigest(str) }
  str
end

pid, read_io = Process.run_with_fork do |write_io|
  write_io.puts heavy_operation("bla")
end

res = read_io.gets
read_io.close

puts res

