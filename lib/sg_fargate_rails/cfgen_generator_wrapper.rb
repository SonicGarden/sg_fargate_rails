require 'tmpdir'

require_relative "generator_wrapper"

module SgFargateRails
  class CfgenGeneratorWrapper < GeneratorWrapper

    def initialize
      @repository = 'cf_fargate_rails_generator'
    end

    private

    def run_command(argv)
      commands = if argv.empty?
                   [
                     %w[bundle exec cf_fargate_rails_generator generate],
                     %w[bundle exec rails generate cf_fargate_rails_generator],
                     %w[bundle exec rails cf_fargate_rails_generator:check],
                   ]
                 elsif argv.first == 'check'
                   [
                     %w[bundle exec rails cf_fargate_rails_generator:check],
                   ]
                 else
                   # Tulio 作業として、AWS構築や構成変更を実施する際に使います
                   # 例) パイプライン(service)更新: "bundle exec cfgen update staging pipeline-service"
                   [
                     ['bundle', 'exec', 'cf_fargate_rails_generator', *argv],
                   ]
                 end

      commands.each do |command|
        unless system(*command, in: :in)
          puts 'エラーが発生しました。中断します。'
          break
        end
      end
    end
  end
end
