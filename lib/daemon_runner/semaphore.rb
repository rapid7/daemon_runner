module DaemonRunner
  #
  # Manage semaphore locks with Consul
  #
  class Semaphore
    include Logger

    # The Consul session
    attr_reader :session

    # The current state of the semaphore
    attr_reader :state

    # The Consul key prefix
    attr_reader :prefix

    def initialize(name, prefix = nil)
      @session = Session.start(name)
      @prefix = prefix.nil? ? "service/#{name}/lock/" : prefix
      @prefix += '/' unless @prefix.end_with?('/')
    end

    # Create a contender key
    def contender_key(value = 'none')
      raise ArgumentError 'Value cannot be empty or nil' if value.nil? || value.empty?
      key = "#{prefix}/#{session.id}"
      Diplomat::Kv.put(key, value, acquire: session.id)
    end

    # Get the current semaphore state by fetching all
    # conterder keys and the lock key
    def semaphore_state
      options = {recurse: true, keys: true}
      keys = Diplomat::Kv.get(prefix, options, :return) 
      return @state = [] if keys.empty?
      @state = keys.map { |k| k.split('/')[-1] }
    end
  end
end
