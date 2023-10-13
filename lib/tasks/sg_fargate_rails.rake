namespace :sg_fargate_rails do
  desc 'EventBridge Schedules'
  task recreate_schedules: :environment do
    require 'net/http'
    require 'json'
    require 'aws-sdk-ec2'
    require 'aws-sdk-scheduler'

    response = Net::HTTP.get(URI.parse("#{ENV['ECS_CONTAINER_METADATA_URI']}/task"))
    meta_data = JSON.parse(response, symbolize_names: true)
    cluster_arn = meta_data[:Cluster]
    account_id = cluster_arn.split(':')[4]
    task_definition_arn = cluster_arn.split(":cluster/")[0] + ':task-definition/' + meta_data[:Family] + ':' + meta_data[:Revision]
    schedule_group_name = "#{ENV['COPILOT_APPLICATION_NAME']}-#{ENV['COPILOT_ENVIRONMENT_NAME']}" # TODO: 取得できなかたらどうする
    region = ENV['AWS_REGION'] || 'ap-northeast-1'
    timezone = ENV['TZ'] || 'Asia/Tokyo'
    credentials = Aws::ECSCredentials.new(retries: 3)

    ec2_client = Aws::EC2::Client.new(region: region, credentials: credentials)
    security_group_params = {
      filters: [
        {
          name: 'tag:aws:cloudformation:logical-id',
          values: ['EnvironmentSecurityGroup'],
        },
        {
          name: 'tag:aws:cloudformation:stack-name',
          values: [schedule_group_name],
        }
      ],
    }
    resp = ec2_client.describe_security_groups(security_group_params)
    security_group_ids = resp.to_h[:security_groups].map { |group| group[:group_id] }
    Rails.logger.info "[INFO] security_group_ids: #{security_group_ids}"

    subnet_params = {
      filters: [
        {
          name: 'tag:aws:cloudformation:logical-id',
          values: %w[PublicSubnet1 PublicSubnet2],
        },
        {
          name: 'tag:aws:cloudformation:stack-name',
          values: [schedule_group_name],
        },
      ],
    }
    resp = ec2_client.describe_subnets(subnet_params)
    subnet_ids = resp.to_h[:subnets].map { |subnet| subnet[:subnet_id] }
    Rails.logger.info "[INFO] subnet_ids: #{subnet_ids}"

    role_arn = "arn:aws:iam::#{account_id}:role/#{schedule_group_name}-eventbridge-scheduler-role"

    client = Aws::Scheduler::Client.new(region: region, credentials: credentials)
    Rails.logger.info "[EventBridgeSchedule] Clear all schedules in #{schedule_group_name}"
    client.list_schedules(group_name: schedule_group_name, max_results: 100).schedules.each do |schedule|
      client.delete_schedule(name: schedule.name, group_name: schedule_group_name)
      Rails.logger.info "[EventBridgeSchedule] Deleted #{schedule_group_name}/#{schedule.name}"
    end

    Rails.logger.info "[EventBridgeSchedule] Register schedules in #{schedule_group_name}"
    schedules = YAML.load File.open(Rails.root.join('config', 'eventbridge_schedules.yml'))
    schedules.each do |name, info|
      params = {
        name: name,
        state: 'ENABLED',
        flexible_time_window: { mode: 'OFF' },
        group_name: schedule_group_name,
        schedule_expression: info["cron"],
        schedule_expression_timezone: timezone,
        target: {
          arn: cluster_arn,
          ecs_parameters: {
            task_count: 1,
            task_definition_arn: task_definition_arn,
            launch_type: 'FARGATE',
            network_configuration: {
              awsvpc_configuration: {
                assign_public_ip: 'ENABLED',
                security_groups: security_group_ids,
                subnets: subnet_ids,
              },
            },
          },
          input: {
            "containerOverrides": [
              {
                "name": "rails",
                "command": ["bundle", "exec"] + info["command"].split(" "),
              }
            ]
          }.to_json,
          retry_policy: {
            maximum_event_age_in_seconds: 120,
            maximum_retry_attempts: 2,
          },
          role_arn: role_arn,
        },
      }
      client.create_schedule(params)
    end
  end
end
