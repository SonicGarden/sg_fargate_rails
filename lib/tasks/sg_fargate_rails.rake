namespace :sg_fargate_rails do
  require 'sg_fargate_rails'

  desc 'EventBridge Schedules'
  task recreate_schedules: :environment do
    require 'aws-sdk-scheduler'

    ecs_task = SgFargateRails::CurrentEcsTask.new
    security_group_ids = ecs_task.security_group_ids
    Rails.logger.info "[INFO] security_group_ids: #{ecs_task.security_group_ids}"

    subnet_ids = ecs_task.public_subnet_ids
    Rails.logger.info "[INFO] subnet_ids: #{subnet_ids}"

    region = ENV['AWS_REGION'] || 'ap-northeast-1'
    timezone = ENV['TZ'] || 'Asia/Tokyo'

    credentials = Aws::ECSCredentials.new(retries: 3)
    client = Aws::Scheduler::Client.new(region: region, credentials: credentials)
    Rails.logger.info "[EventBridgeSchedule] Clear all schedules in #{ecs_task.cfn_stack_name}"
    client.list_schedules(group_name: ecs_task.cfn_stack_name, max_results: 100).schedules.each do |schedule|
      client.delete_schedule(name: schedule.name, group_name: ecs_task.cfn_stack_name)
      Rails.logger.info "[EventBridgeSchedule] Deleted #{ecs_task.cfn_stack_name}/#{schedule.name}"
    end

    Rails.logger.info "[EventBridgeSchedule] Register schedules in #{ecs_task.cfn_stack_name}"
    role_arn = "arn:aws:iam::#{ecs_task.account_id}:role/#{ecs_task.cfn_stack_name}-eventbridge-scheduler-role"
    schedules = YAML.load File.open(Rails.root.join('config', 'eventbridge_schedules.yml'))
    schedules.each do |name, info|
      params = {
        name: name,
        state: 'ENABLED',
        flexible_time_window: { mode: 'OFF' },
        group_name: ecs_task.cfn_stack_name,
        schedule_expression: info["cron"],
        schedule_expression_timezone: timezone,
        target: {
          arn: ecs_task.cluster_arn,
          ecs_parameters: {
            task_count: 1,
            task_definition_arn: ecs_task.task_definition_arn,
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
