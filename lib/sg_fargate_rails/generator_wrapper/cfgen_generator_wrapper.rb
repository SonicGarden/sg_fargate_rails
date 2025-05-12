require 'tmpdir'

require_relative "../generator_wrapper"

module SgFargateRails
  class CfgenGeneratorWrapper < GeneratorWrapper

    def initialize
      @repository = 'cf_fargate_rails_generator'
    end

    private

    def run_command(argv)
      commands = if argv.empty?
                  [
                    %w[bundle exec cf_fargate_rails_generator generate]  
                    # [TODO]sfgen の Copilot 以外の取り込みができたら以下をアンコメントする
                    # %w[bundle exec rails generate cf_fargate_rails_generator],
                    # %w[bundle exec rails cf_fargate_rails_generator:check]
                  ]
                else
                  [
                    ['bundle', 'exec', 'cf_fargate_rails_generator', *argv]
                  ]
                end

      commands.each do |command|
        system(*command, in: :in)
      end
    end
  end
end
