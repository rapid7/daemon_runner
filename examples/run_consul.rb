#!/usr/bin/env ruby

require 'dev/consul'

::Dev::Consul.run
::Dev::Consul.wait
::Dev::Consul.block
