# frozen_string_literal: true

require 'thor'

module StoryBranch
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    desc 'version', 'story_branch gem version'
    def version
      require_relative 'version'
      puts "v#{StoryBranch::VERSION}"
    end
    map %w[--version -v] => :version

    desc 'start', 'Mark an estimated story as started in Pivotal Tracker'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def start(*)
      if options[:help]
        invoke :help, ['start']
      else
        require_relative 'commands/start'
        StoryBranch::Commands::Start.new(options).execute
      end
    end

    desc 'finish', 'Creates a git commit message for the staged changes with a [Finishes] tag'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def finish(*)
      if options[:help]
        invoke :help, ['finish']
      else
        require_relative 'commands/finish'
        StoryBranch::Commands::Finish.new(options).execute
      end
    end

    desc 'create', 'Create branch from estimated stories in pivotal tracker'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def create(*)
      if options[:help]
        invoke :help, ['create']
      else
        require_relative 'commands/create'
        StoryBranch::Commands::Create.new(options).execute
      end
    end

    desc 'add', 'Add a new story branch configuration'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def add(*)
      if options[:help]
        invoke :help, ['add']
      else
        require_relative 'commands/add'
        StoryBranch::Commands::Add.new(options).execute
      end
    end

    desc 'migrate', 'Migrate old story branch configuration to the new format'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def migrate(*)
      if options[:help]
        invoke :help, ['migrate']
      else
        require_relative 'commands/migrate'
        StoryBranch::Commands::Migrate.new(options).execute
      end
    end
  end
end
