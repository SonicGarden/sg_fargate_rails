require 'rack'
require 'rack/request'

module SgFargateRails
  class Maintenance
    def initialize(app, options = {})
      @app = app
    end

    def call(env)
      if maintenance_mode?
        headers = { 'Content-Type' => 'text/html' }
        [503, headers, File.open(maintenance_file_path)]
      else
        @app.call(env)
      end
    end

    private

    def maintenance_mode?
      env['HTTP_X_SG_FARGATE_RAILS_MAINTENANCE'] == 'true'
    end

    def maintenance_file_path
      Rails.public_path.join('503.html')
    end
  end
end
