#!/usr/bin/env ruby

require_relative '../lib/daemon_runner'
require 'dev/consul'

@service = 'myservice'
@lock_count = 3
@locked = false

@semaphore = DaemonRunner::Semaphore.start(@service)

def locked?
  lock = DaemonRunner::Semaphore.lock(@lock_count)
  msg = 'Lock %{text} obtained'
  text = lock == true ? 'succesfully' : 'could not be'
  msg = msg % { text: text }
  @semaphore.logger.debug msg
  lock
end

loop do
  locked?
  sleep 1
end
