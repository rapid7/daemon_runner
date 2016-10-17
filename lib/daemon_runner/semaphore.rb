module DaemonRunner
  #
  # Manage semaphore locks with Consul
  #
  class Semaphore
    include Logger

    class << self

      # Create a session
      #
      # @param name [String] The name of the session, usually the service name
      # @see #initialize for extra `options`
      def start(name, **options)
        options.merge!(name: name)
        @lock ||= Semaphore.new(options)
      end

      # Acquire a lock with the current session
      #
      # @param limit [Integer] The number of nodes that can request the lock
      # @return [Boolean] `true` if the lock was acquired
      #
      def lock(limit = 3)
        raise RuntimeError 'Must call start first' if @lock.nil?
        @lock.limit = limit
        @lock.contender_key
        @lock.semaphore_state
        @lock.write_lock
      end
    end

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

    # The number of nodes that can obtain a semaphore lock
    attr_accessor :limit

    # @param name [String] The name of the session, it is also used in the `prefix`
    # @param prefix [String|NilClass] The Consul Kv prefix
    # @param lock [String|NilClass] The path to the lock file
    def initialize(name:, prefix: nil, lock: nil)
      @session = Session.start(name, behavior: 'delete')
      @prefix = prefix.nil? ? "service/#{name}/lock/" : prefix
      @prefix += '/' unless @prefix.end_with?('/')
      @lock = lock.nil? ? "#{@prefix}.lock" : lock
      @lock_modify_index = nil
      @lock_content = nil
    end

    # Create a contender key
    def contender_key(value = 'none')
      if value.nil? || value.empty?
        raise ArgumentError 'Value cannot be empty or nil'
      end
      key = "#{prefix}/#{session.id}"
      Diplomat::Lock.acquire(key, session.id, value)
    end

    # Get the current semaphore state by fetching all
    # conterder keys and the lock key
    def semaphore_state
      options = { decode_values: true, recurse: true }
      @state = Diplomat::Kv.get(prefix, options, :return)
      decode_semaphore_state unless state.empty?
      state
    end

    # Write a new lock file if the number of contenders is less than `limit`
    # @return [Boolean] `true` if the lock was written succesfully
    def write_lock
      index = lock_exists? ? lock_modify_index : 0
      value = generate_lockfile
      return if value.nil?
      Diplomat::Kv.put(@lock, value, cas: index)
    end

    private

    # Decode raw response from Consul
    # Set `@lock_modify_index`, `@lock_content`, and `@members`
    # @returns [Array] List of members
    def decode_semaphore_state
      lock_key = state.find { |k| k['Key'] == lock }
      member_keys = state.delete_if { |k| k['Key'] == lock }
      member_keys.map! { |k| k['Key'] }

      unless lock_key.nil?
        @lock_modify_index = lock_key['ModifyIndex']
        @lock_content = JSON.parse(lock_key['Value'])
      end
      @members = member_keys.map { |k| k.split('/')[-1] }
    end

    # Returns current state of lockfile
    def lock_exists?
      !lock_modify_index.nil? && !lock_content.nil?
    end

    # Get the active members from the lock file, removing any _dead_ members
    # This is accomplished by using the contenders keys(`@members`) to get the
    # list of all alive members.  So we can easily remove any nodes that don't
    # appear in that list.
    def active_members
      if lock_exists?
        holders = lock_content['Holders']
        holders = holders.keys
        holders & members
      else
        []
      end
    end

    # Format the list of holders for the lock file
    def holders
      holders = {}
      members = active_members
      members << session.id if members.length < limit
      members.map { |m| holders[m] = true }
      holders
    end

    # Generate JSON formatted lockfile content, only if he number of contenders
    # is less than `limit`
    def generate_lockfile
      return if active_members.length >= limit
      lockfile_format = {
        'Limit' => limit,
        'Holders' => holders
      }
      JSON.generate(lockfile_format)
    end
  end
end
