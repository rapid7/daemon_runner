#!/usr/bin/env ruby

require_relative '../lib/daemon_runner'
require 'dev/consul'

@service = 'myreleaseservice'
@lock_count = 3
@lock_time = 10

::Dev::Consul.run
::Dev::Consul.wait

DaemonRunner::Semaphore.lock(@service, @lock_count) do
  @lock_time.downto(0).each do |i|
   puts "Releasing lock in #{i} seconds"
   sleep 1
  end
end

::Dev::Consul.stop
