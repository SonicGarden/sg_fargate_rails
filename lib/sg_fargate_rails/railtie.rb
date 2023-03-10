require 'sg_fargate_rails/healthcheck'

module SgFargateRails
  class Railtie < ::Rails::Railtie
    initializer :initialize_sg_fargate_rails do |_app|
      unless ::Rails.env.in?(%w[development test])
        middleware = ::Rails.configuration.middleware
        middleware.insert 0, SgFargateRails::Healthcheck
      end
    end
  end
end
