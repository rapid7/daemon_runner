#!/usr/bin/env ruby

require_relative '../lib/daemon_runner'
require 'dev/consul'

@service = 'myservice'
@lock_count = 3
@locked = false

@semaphore = DaemonRunner::Semaphore.start(@service)
DaemonRunner::Semaphore.lock(@lock_count)
