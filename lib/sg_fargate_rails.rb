# frozen_string_literal: true

require_relative "sg_fargate_rails/version"
require 'lograge'

if defined?(::Rails::Railtie)
  require 'sg_fargate_rails/railtie'
else
  puts 'Please SgFargateRails setup by manual.'
end

module SgFargateRails
  class Error < StandardError; end
end
