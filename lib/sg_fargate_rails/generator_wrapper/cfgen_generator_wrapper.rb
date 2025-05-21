require 'tmpdir'

require_relative "../generator_wrapper"

module SgFargateRails
  class CfgenGeneratorWrapper < GeneratorWrapper

    def initialize
      @repository = 'cf_fargate_rails_generator'
    end

    private

    def run_command(argv)
      task = argv.shift
      commands = case task
                 when nil
                   [
                     %w[bundle exec cf_fargate_rails_generator generate],
                     %w[bundle exec rails generate cf_fargate_rails_generator],
                     %w[bundle exec rails cf_fargate_rails_generator:check],
                   ]
                 when 'check'
                   [
                     %w[bundle exec rails cf_fargate_rails_generator:check],
                   ]
                 else
                   # Tulio 作業として、例えば "bundle exec cfgen update staging pipeline-env" などを実行する場合に使います
                   [
                     ['bundle', 'exec', 'cf_fargate_rails_generator', task, *argv],
                   ]
                 end

      commands.each do |command|
        system(*command, in: :in)
      end
    end
  end
end
