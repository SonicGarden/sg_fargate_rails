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
          # [TODO]sfgen の Copilot 以外の取り込みができたら以下をアンコメントする
          # %w[bundle exec rails generate cf_fargate_rails_generator],
          %w[bundle exec rails cf_fargate_rails_generator:check],
        ]
      when 'check'
        [
          %w[bundle exec rails cf_fargate_rails_generator:check],
        ]
      when 'app-gen'
        [
          %w[bundle exec rails generate cg_fargate_rails_generator],
        ]
      else
        [
          ['bundle', 'exec', 'cf_fargate_rails_generator', *argv],
        ]
      end

      commands.each do |command|
        system(*command, in: :in)
      end
    end
  end
end
