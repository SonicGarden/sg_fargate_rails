require 'tmpdir'

require_relative "../generator_wrapper"

module SgFargateRails
  class SfgenGeneratorWrapper < GeneratorWrapper

    def initialize
      @repository = 'sg_fargate_rails_generator'
    end

    private

    def run_command(argv)
      task = argv.first
      commands = if task
                   [
                     ['bundle', 'exec', 'rails', "sg_fargate_rails_generator:#{task}"]
                   ]
                 else
                   [
                     %w[bundle exec rails generate sg_fargate_rails_generator],
                     %w[bundle exec rails sg_fargate_rails_generator:check]
                   ]
                 end

      commands.each do |command|
        system(*command, in: :in)
      end
    end
  end
end
