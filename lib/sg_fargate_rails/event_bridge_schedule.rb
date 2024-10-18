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

    DEFAULT_STORAGE_SIZE_GB = 20

    attr_reader :name

    def initialize(name:, cron:, command:, container_type: 'small', storage_size_gb: nil, use_bundler: true)
      @name = name
      @cron = cron
      @command = command
      @container_type = container_type
      @storage_size_gb = storage_size_gb # sizeInGiB
      @use_bundler = use_bundler
    end

    # TODO: 利用しなくなる (state machine に移行する) ので、このメソッドは削除する
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

    def create_start_execution_state_machine(group_name:, cluster_arn:)
      params = {
        name: @name,
        state: 'ENABLED',
        flexible_time_window: { mode: 'OFF' },
        group_name: group_name,
        schedule_expression: @cron,
        schedule_expression_timezone: timezone,
        target: {
          arn: state_machine_arn(group_name, cluster_arn),
          input: state_machine_input_json,
          retry_policy: {
            maximum_event_age_in_seconds: 120,
            maximum_retry_attempts: 2,
          },
          role_arn: role_arn_for_state_machine(group_name, cluster_arn),
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

    def state_machine_input_json
      type = convert_container_type
      {
        **type,
        "storage_size_gb": @storage_size_gb || DEFAULT_STORAGE_SIZE_GB,
        "command": container_command,
      }.to_json
    end

    def convert_container_type
      CONTAINER_TYPES.fetch(@container_type)
    end

    def convert_storage_size
      @storage_size_gb.present? ? { "ephemeralStorage": { "sizeInGiB": @storage_size_gb } } : {}
    end

    def container_command
      if use_bundler?
        %w[bundle exec] + splitted_command
      else
        splitted_command
      end
    end

    def use_bundler?
      !!@use_bundler
    end

    private

    def timezone
      ENV['TZ'] || 'Asia/Tokyo'
    end

    def account_id(cluster_arn)
      cluster_arn.split(':')[4]
    end

    def role_arn_for(group_name, cluster_arn)
      "arn:aws:iam::#{account_id(cluster_arn)}:role/#{group_name}-eventbridge-scheduler-role"
    end

    def role_arn_for_state_machine(group_name, cluster_arn)
      "arn:aws:iam::#{account_id(cluster_arn)}:role/#{group_name}-step-functions-state-machine-role"
    end

    def client
      self.class.client
    end

    def splitted_command
      if @command.is_a?(Array)
        @command
      else
        @command.split(' ')
      end
    end

    def region
      ENV['AWS_REGION'] || 'ap-northeast-1'
    end

    def state_machine_arn(group_name, cluster_arn)
      "arn:aws:states:#{region}:#{account_id(cluster_arn)}:stateMachine:#{group_name}-rails-state-machine"
    end

    class << self
      def convert(schedules)
        schedules.to_h.map { |name, info|
          EventBridgeSchedule.new(
            name: name.to_s,
            **info.slice(:cron, :command, :container_type, :storage_size_gb, :use_bundler)
          )
        }
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
