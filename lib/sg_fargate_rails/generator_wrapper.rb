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
      `git clone --quiet --depth 1 git@github.com:SonicGarden/#{@repository}.git "#{tempdir}"`
    end

    def bundle_add
      `bundle add #{@repository} --path "#{tempdir}" --group development`
    end

    def run_command(argv)
      raise NotImplementedError, 'Sub Class must implement run_command method'
    end

    def bundle_remove
      `bundle remove #{@repository}`
    end

    def remove_tempdir
      FileUtils.rm_rf(tempdir)
    end

    def tempdir
      @tempdir ||= Dir.mktmpdir
    end
  end
end
