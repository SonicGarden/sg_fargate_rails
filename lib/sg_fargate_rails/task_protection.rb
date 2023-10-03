module SgFargateRails
  class TaskProtection
    class << self
      def manager
        @manager ||= Manager.new
      end

      def with_task_protection
        manager.protect
        yield
      ensure
        manager.unprotect
      end
    end

    class Manager
      def initialize
        @mutex = Mutex.new
        @runnings = 0
      end

      def protect
        @mutex.synchronize do
          @runnings += 1
          if @runnings == 1
            update_task_protection_state(enabled: true)
          end
        end
      end

      def unprotect
        @mutex.synchronize do
          @runnings -= 1
          if @runnings == 0
            update_task_protection_state(enabled: false)
          end
        end
      end

      private

      def ecs_agent_uri(path)
        URI(%(#{ENV['ECS_AGENT_URI']}#{path}))
      end

      def update_task_protection_state(enabled:)
        uri = ecs_agent_uri('/task-protection/v1/state')
        req = Net::HTTP::Put.new(uri.path)
        req.add_field('Content-Type', 'application/json')
        req.body = { 'ProtectionEnabled' => enabled }.to_json

        code, body = send_http_request(uri, req)
        if code == 200
          Rails.logger.info "[SgFargateRails::TaskProtection] succeeded; enabled=#{enabled}"
        else
          Rails.logger.info "[SgFargateRails::TaskProtection] failed; enabled=#{enabled}, code=#{code}, res=#{body}"
        end
      end

      def send_http_request(uri, request)
        if Rails.env.test? || Rails.env.development?
          [200, nil]
        else
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          res = http.request(request)
          [res.code.to_i, res.body]
        end
      end
    end

    module Job
      def self.included(mod)
        mod.around_perform do
          TaskProtection.with_task_protection do
            yield
          end
        end
      end
    end
  end
end
