module SgFargateRails
  class AdjustCloudfrontHeaders
    def initialize(app)
      @app = app
    end

    def call(env)
      env['HTTP_X_FORWARDED_PROTO'] = 'https'

      @app.call(env)
    end
  end
end
