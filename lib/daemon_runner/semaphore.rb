module DaemonRunner
  #
  # Manage semaphore locks with Consul
  #
  class Semaphore
    include Logger

    # The Consul session
    attr_reader :session

    def initialize(name, prefix = nil)
      @session = Session.start(name)
      @prefix = prefix.nil? ? "service/#{name}/lock" : prefix
    end

    # Create a contender key
    def contender_key(value = 'none')
      raise ArgumentError 'Value cannot be empty or nil' if value.nil? || value.empty?
      key = "#{@prefix}/#{session.id}"
      Diplomat::Kv.put(key, value, acquire: session.id)
    end
  end
end
