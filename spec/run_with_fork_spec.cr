require "./spec_helper"

describe RunWithFork do
  it "simple" do
    pid, read_io = Process.run_with_fork do |write_io|
      write_io.puts heavy_operation("bla")
    end

    res = read_io.gets
    read_io.close

    res.should eq "078b909058e63b46974054bfc92a7e92"
    res.should eq heavy_operation("bla")
  end

  it "concurrent" do
    ch = Channel(Bool).new

    t = Time.local

    10.times do
      spawn do
        interval = rand(1.0)

        pid, r = Process.run_with_fork(disable_gc: true) do |w|
          usleep = (interval * 1_000_000).to_i
          LibC.usleep(usleep)

          # just send some data
          1.to_msgpack(w)
          interval.to_msgpack(w)
          "done".to_msgpack(w)
        end

        pull = MessagePack::Unpacker.new(r)
        pull.read.should eq 1
        usleep = pull.read_float
        usleep.should be >= 0
        usleep.should be < 1_000_000
        pull.read_string.should eq "done"

        r.close

        ch.send(true)
      end
    end

    10.times { ch.receive }

    delta = (Time.local - t).to_f

    delta.should be >= 0.0
    delta.should be <= 1.1
  end

  it "fork should exit when read io is closed" do
    File.exists?(FILENAME).should eq false

    pid, r = Process.run_with_fork do |w|
      begin
        w.puts("writing")
      ensure
        File.open(FILENAME, "w") { |f| f << "ok" }
      end
    end

    # r.close
    sleep 0.1

    File.exists?(FILENAME).should eq true
  end
end
