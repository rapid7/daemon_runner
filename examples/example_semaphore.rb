#!/usr/bin/env ruby

require_relative '../lib/daemon_runner'
require 'dev/consul'

@service = 'myservice'
@lock_count = 3
@lock_time = 10

::Dev::Consul.run
::Dev::Consul.wait

# Get a new semaphore
@semaphore = DaemonRunner::Semaphore.lock(@service, @lock_count)

# Spawn a thread to handle renewing the lock
@renew_thread = @semaphore.renew

# Do whatever kind of work you want
@lock_time.downto(0).each do |i|
  puts "Releasing lock in #{i} seconds"
  sleep 1
end

# Kill the thread when you're done
@renew_thread.kill

# Explicitly release the semaphore when you're done
@semaphore.release

::Dev::Consul.stop
