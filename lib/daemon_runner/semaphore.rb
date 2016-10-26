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
      # @return [Thread] Thread running a blocking call maintaining the lock state
      #
      def lock(limit = 3)
        raise RuntimeError, 'Must call start first' if @lock.nil?
        @lock.contender_key
        @lock.semaphore_state
        @lock.set_limit(limit)
        @lock.try_lock

        thr = Thread.new do
          loop do
            if @lock.renew?
              @lock.semaphore_state
              @lock.try_lock
            end
          end
        end
        thr
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
    attr_reader :limit

    # @param name [String] The name of the session, it is also used in the `prefix`
    # @param prefix [String|NilClass] The Consul Kv prefix
    # @param lock [String|NilClass] The path to the lock file
    def initialize(name:, prefix: nil, lock: nil)
      create_session(name)
      @prefix = prefix.nil? ? "service/#{name}/lock/" : prefix
      @prefix += '/' unless @prefix.end_with?('/')
      @lock = lock.nil? ? "#{@prefix}.lock" : lock
      @lock_modify_index = nil
      @lock_content = nil
      @limit = nil
      @reset = false
    end

    def create_session(name)
      ::DaemonRunner::RetryErrors.retry(exceptions: [DaemonRunner::Session::CreateSessionError]) do
        @session = Session.start(name, behavior: 'delete')
      end
    end

    # FIXME: Cannot clear limit, when there have been 0 active locks
    # The number of nodes that can obtain a semaphore lock
    def set_limit(new_limit)
      if lock_exists?
        if new_limit.to_i != @limit.to_i
          logger.warn 'Limit in lockfile and @limit do not match using limit from lockfile'
        end
        @limit = lock_content['Limit']
      else
        @limit = new_limit
      end
    end

    # Create a contender key
    def contender_key(value = 'none')
      if value.nil? || value.empty?
        raise ArgumentError, 'Value cannot be empty or nil'
      end
      key = "#{prefix}/#{session.id}"
      ::DaemonRunner::RetryErrors.retry do
        @contender_key = Diplomat::Lock.acquire(key, session.id, value)
      end
      @contender_key
    end

    # Get the current semaphore state by fetching all
    # conterder keys and the lock key
    def semaphore_state
      options = { decode_values: true, recurse: true }
      @state = Diplomat::Kv.get(prefix, options, :return)
      decode_semaphore_state unless state.empty?
      state
    end

    def try_lock
      prune_members
      do_update = add_self_to_holders
      if do_update
        format_holders
        write_lock
      end
      locked?
    end

    # Write a new lock file if the number of contenders is less than `limit`
    # @return [Boolean] `true` if the lock was written succesfully
    def write_lock
      index = lock_modify_index.nil? ? 0 : lock_modify_index
      value = generate_lockfile
      return true if value == true
      @locked = Diplomat::Kv.put(@lock, value, cas: index)
    end

    # Start a blocking query on the prefix, if there are changes
    # we need to try to obtain the lock again.
    #
    # @return [Boolean] `true` if there are changes,
    #  `false` if the request has timed out
    def renew?
      logger.debug("Watching Consul #{prefix} for changes")
      options = { recurse: true }
      changes = Diplomat::Kv.get(prefix, options, :wait, :wait)
      logger.info("Changes on #{prefix} detected") if changes
      changes
    rescue StandardError => e
      logger.error(e)
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
      (!lock_modify_index.nil? && !lock_content.nil?) && !@reset
    end

    # Get the active members from the lock file, removing any _dead_ members.
    # This is accomplished by using the contenders keys(`@members`) to get the
    # list of all alive members.  So we can easily remove any nodes that don't
    # appear in that list.
    def prune_members
      @holders = if lock_exists?
        holders = lock_content['Holders']
        return @holders = [] if holders.nil?
        holders = holders.keys
        holders & members
      else
        []
      end
    end

    # Add our session.id to the holders list if holders is less than limit
    def add_self_to_holders
      @holders.uniq!
      @reset = true if @holders.length == 0
      return true if @holders.include? session.id
      if @holders.length < limit
        @holders << session.id
      end
    end

    # Format the list of holders for the lock file
    def format_holders
      @holders.uniq!
      @holders.sort!
      holders = {}
      logger.debug "Holders are: #{@holders.join(',')}"
      @holders.map { |m| holders[m] = true }
      @holders = holders
    end

    # Generate JSON formatted lockfile content, only if the content has changed
    def generate_lockfile
      if lock_exists? && lock_content['Holders'] == @holders
        logger.info 'Holders are unchanged, not updating'
        return true
      end
      lockfile_format = {
        'Limit' => limit,
        'Holders' => @holders
      }
      JSON.generate(lockfile_format)
    end

    def locked?
      msg = 'Lock %{text} obtained'
      text = @locked == true ? 'succesfully' : 'could not be'
      msg = msg % { text: text }
      logger.info msg
    end
  end
end
