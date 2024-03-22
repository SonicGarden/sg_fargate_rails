require 'tmpdir'

module SgFargateRails
  class GeneratorWrapper
    def self.run(argv)
      new.run(argv)
    end

    def run(argv)
      clone_to_tempdir
      bundle_add
      run_command(argv)
      bundle_remove
      remove_tempdir
    end

    private

    def clone_to_tempdir
      `git clone --quiet --depth 1 git@github.com:SonicGarden/sg_fargate_rails_generator.git "#{tempdir}"`
    end

    def bundle_add
      `bundle add sg_fargate_rails_generator --path "#{tempdir}" --group development`
    end

    def run_command(argv)
      task = argv.first
      command = if task
                  ['bundle', 'exec', 'rails', "sg_fargate_rails_generator:#{task}"]
                else
                  %w[bundle exec rails generate sg_fargate_rails_generator]
                end
      system(*command, in: :in)
    end

    def bundle_remove
      `bundle remove sg_fargate_rails_generator`
    end

    def remove_tempdir
      FileUtils.rm_rf(tempdir)
    end

    def tempdir
      @tempdir ||= Dir.mktmpdir
    end
  end
end
