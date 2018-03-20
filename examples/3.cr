require "../src/run_with_fork"
require "msgpack"

read_io = Process.run_with_fork do |write_io|
  1.to_msgpack(write_io)
  "done".to_msgpack(write_io)
  [1, 2, 3].to_msgpack(write_io)
end

pull = MessagePack::Unpacker.new(read_io)

p pull.read_uint         # => 1_u8
p pull.read_string       # => "done"
p Array(Int32).new(pull) # => [1, 2, 3]

read_io.close
