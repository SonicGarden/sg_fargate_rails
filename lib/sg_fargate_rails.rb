# frozen_string_literal: true

require_relative "sg_fargate_rails/version"
require_relative "sg_fargate_rails/config"
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
