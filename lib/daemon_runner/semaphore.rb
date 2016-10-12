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

    # The current semaphore members
    attr_reader :members

    # The current lock modify index
    attr_reader :lock_modify_index

    # The lock content
    attr_reader :lock_content

    # The Consul key prefix
    attr_reader :prefix

    # The Consul lock key
    attr_reader :lock

    def initialize(name, prefix = nil, lock = nil)
      @session = Session.start(name)
      @prefix = prefix.nil? ? "service/#{name}/lock/" : prefix
      @prefix += '/' unless @prefix.end_with?('/')
      @lock = lock.nil? ? "#{prefix}/.lock" : lock
    end

    # Create a contender key
    def contender_key(value = 'none')
      if value.nil? || value.empty?
        raise ArgumentError 'Value cannot be empty or nil'
      end
      key = "#{prefix}/#{session.id}"
      Diplomat::Kv.put(key, value, acquire: session.id)
    end

    # Get the current semaphore state by fetching all
    # conterder keys and the lock key
    def semaphore_state
      options = { decode_values: true, recurse: true }
      @state = Diplomat::Kv.get(prefix, options, :return)
      unless @state.empty?
        member_keys = @state.map { |k| k['Key'] }
        if member_keys.include?(@lock)
          lock_key = @state.delete_if { |k| k['Key'] == @lock }
          @lock_modify_index = lock_key['ModifyIndex']
          @lock_content = JSON.parse(Base64.decode64(lock_key['Value']))
        end
        @members = member_keys.map { |k| k.split('/')[-1] }
      end
      @state
    end

    # Returns current state of lockfile
    def lock_exists?
      !lock_modify_index.nil? && !lock_content.nil?
    end

    def active_members
      if lock_exists?
        holders = lock_content['Holders']
        holders = holders.keys
        holders & members
      end
    end
  end
end
