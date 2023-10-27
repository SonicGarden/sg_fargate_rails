require "aws-sdk-scheduler"

module SgFargateRails
  class EventBridgeSchedule
    attr_reader :name

    def initialize(name, cron, command, cpu, memory)
      @name = name
      @cron = cron
      @command = command
      @cpu = cpu
      @memory = memory
    end

    def create_run_task(group_name:, cluster_arn:, task_definition_arn:, network_configuration:)
      params = {
        name: @name,
        state: 'ENABLED',
        flexible_time_window: { mode: 'OFF' },
        group_name: group_name,
        schedule_expression: @cron,
        schedule_expression_timezone: timezone,
        target: {
          arn: cluster_arn,
          ecs_parameters: {
            task_count: 1,
            task_definition_arn: task_definition_arn,
            launch_type: 'FARGATE',
            network_configuration: network_configuration
          },
          input: input_overrides_json,
          retry_policy: {
            maximum_event_age_in_seconds: 120,
            maximum_retry_attempts: 2,
          },
          role_arn: role_arn_for(group_name, cluster_arn),
        },
      }
      client.create_schedule(params)
    end

    def input_overrides_json
      if @cpu && @memory
        {
          "cpu": "#{@cpu}",
          "memory": "#{@memory}",
          "containerOverrides": [
            {
              "name": "rails",
              "cpu": "#{@cpu}",
              "memory": "#{@memory}",
              "command": container_command,
            }
          ]
        }.to_json
      else
        {
          "containerOverrides": [
            {
              "name": "rails",
              "command": container_command,
            }
          ]
        }.to_json
      end
    end

    def container_command
      %w[bundle exec] + @command.split(' ')
    end

    private

    def timezone
      ENV['TZ'] || 'Asia/Tokyo'
    end

    def role_arn_for(group_name, cluster_arn)
      account_id = cluster_arn.split(':')[4]
      "arn:aws:iam::#{account_id}:role/#{group_name}-eventbridge-scheduler-role"
    end

    def client
      self.class.client
    end

    class << self
      def parse(filename)
        schedules = YAML.load(File.open(filename))
        schedules.map { |name, info| EventBridgeSchedule.new(name, info['cron'], info['command'], info['cpu'], info['memory']) }
      end

      def delete_all!(group_name)
        client.list_schedules(group_name: group_name, max_results: 100).schedules.each do |schedule|
          client.delete_schedule(name: schedule.name, group_name: group_name)
          Rails.logger.info "[EventBridgeSchedule] Deleted #{group_name}/#{schedule.name}"
        end
      end

      def client
        @client ||= Aws::Scheduler::Client.new(region: region, credentials: credentials)
      end

      def region
        ENV['AWS_REGION'] || 'ap-northeast-1'
      end

      def credentials
        Aws::ECSCredentials.new(retries: 3)
      end
    end
  end
end