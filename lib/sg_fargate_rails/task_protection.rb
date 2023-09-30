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

      def ecs_agent_uri
        ENV['ECS_AGENT_URI']
      end

      def http
        @http ||= begin
                    uri = URI(ecs_agent_uri)
                    http = Net::HTTP.new(uri.host, uri.port)
                    http.use_ssl = uri.scheme == 'https'
                    http
                  end
      end

      def update_task_protection_state(enabled:)
        req = Net::HTTP::Put.new('/task-protection/v1/state')
        req.add_field('Content-Type', 'application/json')
        req.body = { 'ProtectionEnabled' => enabled }.to_json
        res = http.request(req)
        code = res.code.to_i
        if code == 200
          Rails.logger.info "[SgFargateRails::TaskProtection] succeeded; enabled=#{enabled}"
        else
          Rails.logger.info "[SgFargateRails::TaskProtection] failed; enabled=#{enabled}, code=#{code}, res=#{res.body}"
        end
      end
    end

    module Job
      def self.included(mod)
        mod.around_perform do
          TaskProtection.with_task_protection(&block)
        end
      end
    end
  end
end
