# frozen_string_literal: true

require_relative "sg_fargate_rails/version"
require_relative "sg_fargate_rails/config"
require_relative "sg_fargate_rails/current_ecs_task"
require_relative "sg_fargate_rails/event_bridge_schedule"
require_relative "sg_fargate_rails/exit_code"
require 'lograge'

if defined?(::Rails::Railtie)
  require 'sg_fargate_rails/railtie'
else
  puts 'Please SgFargateRails setup by manual.'
end

module SgFargateRails
  class Error < StandardError; end

  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
    end
  end

  class DependencyChecker
    class << self
      def check!
        if current_generator_version < Gem::Version.new('0.13.0')
          raise 'sg_fargate_rails_generator のバージョンを 0.13.0 以上にあげてください'
        end
      end

      def current_generator_version
        file_path = Rails.root.join('.sg_fargate_rails_generator').freeze
        version = File.exist?(file_path) ? File.read(file_path).strip : '0.0.0'
        Gem::Version.new(version)
      end
    end
  end
end
