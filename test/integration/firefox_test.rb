require_relative './test_helper'

describe "firefox" do
  it "runs firefox & can connect to mozrepl" do
    pid = spawn(*%W{/Applications/Firefox.app/Contents/MacOS/firefox -P Testing})
    sleep 5
    begin
      require 'socket'
      tcp = TCPSocket.new 'localhost', 4243
      read_ready, write_ready = IO.select([tcp], [], [], 5)
      read_ready.first.gets # move past newline
      read_ready.first.gets.must_match /MozRepl/
    ensure
      Process.kill "KILL", pid
    end
  end
  it "has firefox" do
    assert dir_exists?("/Applications/Firefox.app")
  end
end
