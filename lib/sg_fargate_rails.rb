# frozen_string_literal: true

require_relative "sg_fargate_rails/version"
require_relative "sg_fargate_rails/config"
require_relative "sg_fargate_rails/current_ecs_task"
require_relative "sg_fargate_rails/event_bridge_schedule"
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
end
