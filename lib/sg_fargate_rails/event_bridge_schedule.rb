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

    DEFAULT_STORAGE_SIZE_GB = 21
    ROLE_NAME_MAX_LENGTH = 64 # AWS IAM の仕様による制限

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

    # TODO: 利用しなくなる (state machine に移行する) ので、 create_run_task 同様に、このメソッドは削除する
    def role_arn_for(group_name, cluster_arn)
      "arn:aws:iam::#{account_id(cluster_arn)}:role/#{group_name}-eventbridge-scheduler-role"
    end

    def role_arn_for_state_machine(group_name, cluster_arn)
      "arn:aws:iam::#{account_id(cluster_arn)}:role/#{role_name(group_name, 'step-functions-state-machine-role')}"
    end

    def role_name(group_name, suffix)
      name = "#{group_name}-#{suffix}"
      return name unless ENV['CFGEN_ENABLED'] == 'true'

      # AWSの仕様により、64文字を超える場合は短縮形にする
      (name.length > ROLE_NAME_MAX_LENGTH) ? shortened_role_name(suffix) : name
    end

    # NOTE: CFgen で作成するロール名の短縮形に合わせる
    # https://github.com/SonicGarden/cf_fargate_rails_generator/blob/4ef5e76e8df5c9984e89603d2be411ac5ee202f5/lib/cf_fargate_rails_generator/render/base.rb#L76-L82
    def shortened_role_name(suffix)
      shortened_application_name = ENV['COPILOT_APPLICATION_NAME'][0...15] # 15文字に切り詰める
      shortened_environment_name = case ENV['COPILOT_ENVIRONMENT_NAME']
                                   when 'production'
                                     'prod'
                                   when 'staging'
                                     'stg'
                                   else
                                     ENV['COPILOT_ENVIRONMENT_NAME']
                                   end
      "cfgen-#{shortened_application_name}-#{shortened_environment_name}-#{suffix}"
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
      container_name = (ENV['CFGEN_ENABLED'] == 'true') ? 'web' : 'rails'
      "arn:aws:states:#{region}:#{account_id(cluster_arn)}:stateMachine:#{group_name}-#{container_name}-state-machine"
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
