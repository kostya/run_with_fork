require "spec"
require "../src/run_with_fork"
require "digest/md5"
require "msgpack"
require "uuid"

def heavy_operation(str)
  1000.times { str = Digest::MD5.hexdigest(str) }
  str
end

lib LibC
  fun usleep(v : Int32)
end

FILENAME = "./test1.txt"

Spec.before_each do
  File.delete(FILENAME) rescue nil
end
