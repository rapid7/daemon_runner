#!/usr/bin/env ruby

require_relative '../lib/daemon_runner'
require 'dev/consul'

@service = 'myservice'
@lock_count = 3
@locked = false

::Dev::Consul.run
::Dev::Consul.wait

# Get a new semaphore
@semaphore = DaemonRunner::Semaphore.lock(@service, @lock_count)

# Spawn a thread to handle renewing the lock
@renew_thread = @semaphore.renew

# Do whatever kind of work you want
puts 'Working...'
sleep 1

# Kill the thread when you're done
@renew_thread.kill

# Explicitly release the semaphore when you're done
@semaphore.release

::Dev::Consul.stop
