require 'diplomat'

module DaemonRunner
  #
  # Manage distributed locks with Consul
  #
  class Session
    class SessionError < RuntimeError; end
    class CreateSessionError < SessionError; end

    include Logger

    class << self
      attr_reader :session

      def start(name, **options)
        @session ||= Session.new(name, options).renew!
        raise CreateSessionError, 'Failed to create session' if @session == false
        @session.verify_session
        @session
      end


      # Acquire a lock with the current session, or initialize a new session
      #
      # @param path [String]  A path in the Consul key-value space to lock
      # @param lock_session [Session] The Session instance to lock the lock to
      # @return [Boolean] `true` if the lock was acquired
      #
      def lock(path)
        Diplomat::Lock.wait_to_acquire(path, session.id)
      end

      # Release a lock held by the current session
      #
      # @param path [String]  A path in the Consul key-value space to release
      # @param lock_session [Session] The Session instance that the lock was acquired with
      #
      def release(path)
        Diplomat::Lock.release(path, session.id)
      end
    end

    # Consul session ID
    attr_reader :id

    # Session name
    attr_reader :name

    # Period, in seconds, after which session expires
    attr_reader :ttl

    # Period, in seconds, that a session's locks will be
    attr_reader :delay

    # Behavior when a session is invalidated, can be set to either release or delete
    attr_reader :behavior

    # @param name [String]  Session name
    # @option options [Fixnum]  ttl (15)    Session TTL in seconds
    # @option options [Fixnum]  delay (15)  Session release dealy in seconds
    # @option options [String]  behavior (release)  Session release behavior
    def initialize(name, **options)
      logger.info('Initializing a Consul session')

      @name = name
      @ttl = options.fetch(:ttl, 15)
      @delay = options.fetch(:delay, 15)
      @behavior = options.fetch(:behavior, 'release')

      init
    end

    # Check if there is an active renew thread
    #
    # @return [Boolean] `true` if the thread is alive
    def renew?
      @renew.is_a?(Thread) && @renew.alive?
    end

    # Create a thread to periodically renew the lock session
    #
    def renew!
      return if renew?

      @renew = Thread.new do
        ## Wakeup every TTL/2 seconds and renew the session
        loop do
          sleep ttl / 2

          begin
            logger.debug(" - Renewing Consul session #{id}")
            Diplomat::Session.renew(id)

          rescue Faraday::ResourceNotFound
            logger.warn("Consul session #{id} has expired!")

            init
          rescue StandardError => e
            ## Keep the thread from exiting
            logger.error(e)
          end
        end
      end

      self
    end

    # Stop the renew thread and destroy the session
    #
    def destroy!
      @renew.kill if renew?
      Diplomat::Session.destroy(id)
    end

    # Verify wheather the session exists after a period of time
    def verify_session(wait_time = 2)
      logger.info(" - Wait until Consul session #{id} exists")
      wait_time.times do
        exists = session_exist?
        raise CreateSessionError, 'Error creating session' unless exists
        sleep 1
      end
      logger.info(" - Found Consul session #{id}")
    rescue CreateSessionError
      init
    end

    private

    # Initialize a session and store it's ID
    #
    def init
      @id = Diplomat::Session.create(
        :Name => name,
        :TTL => "#{ttl}s",
        :LockDelay => "#{delay}s",
        :Behavior => behavior
      )
      logger.info(" - Initialized a Consul session #{id}")
    end

    # Does the session exist
    def session_exist?
      sessions = Diplomat::Session.list
      sessions.any? { |s| s['ID'] == id }
    end
  end
end
