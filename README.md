# run_with_fork

Some simple parallelism for Crystal. Run some heavy or blocked thread operations in background fork. Fork created for every new task and exit when done.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  run_with_fork:
    github: kostya/run_with_fork
```

## Usage

```crystal
require "run_with_fork"
require "digest/md5"

def heavy_operation(str)
  1000.times { str = Digest::MD5.hexdigest(str) }
  str
end

read_io = Process.run_with_fork do |write_io|
  write_io.puts heavy_operation("bla")
end

res = read_io.gets
read_io.close

puts res
```

## Example concurrent

  without fork:

    crystal examples/2.cr --release -- 100 10000 0

    00:00:03.380020000

  with fork:

    crystal examples/2.cr --release -- 100 10000 1

    00:00:00.758754000

```crystal
require "run_with_fork"
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
      r = Process.run_with_fork do |w|
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
```

## Example use msgpack to exchange data

```crystal
require "run_with_fork"
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
```
