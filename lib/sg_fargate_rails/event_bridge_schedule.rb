require "aws-sdk-scheduler"

module SgFargateRails
  class EventBridgeSchedule
    CONTAINER_TYPES = {
      'small' => { cpu: '512', memory: '1024' },
      'medium' => { cpu: '1024', memory: '2048' },
      'large' => { cpu: '2048', memory: '4096' },
      'xlarge' => { cpu: '4096', memory: '8192' },
      '2xlarge' => { cpu: '8192', memory: '16384' },
    }.freeze

    attr_reader :name

    def initialize(name, cron, command, container_type, storage_size_gb)
      @name = name
      @cron = cron
      @command = command
      @container_type = container_type || 'small'
      @storage_size_gb = storage_size_gb # sizeInGiB
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
      type = convert_container_type
      size = convert_storage_size
      {
        **type,
        **size,
        "containerOverrides": [
          {
            "name": "rails",
            **type,
            "command": container_command,
          }
        ]
      }.to_json
    end

    def convert_container_type
      CONTAINER_TYPES.fetch(@container_type)
    end

    def convert_storage_size
      @storage_size_gb.present? ? { "ephemeralStorage": { "sizeInGiB": @storage_size_gb } } : {}
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
      def convert(schedules)
        schedules.to_h.map { |name, info| EventBridgeSchedule.new(name.to_s, info[:cron], info[:command], info[:container_type], info[:storage_size_gb]) }
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
