namespace :sg_fargate_rails do
  require 'sg_fargate_rails'

  desc 'EventBridge Schedules'
  task recreate_schedules: :environment do
    ecs_task = SgFargateRails::CurrentEcsTask.new
    Rails.logger.info "[INFO] security_group_ids: #{ecs_task.security_group_ids}"
    Rails.logger.info "[INFO] subnet_ids: #{ecs_task.public_subnet_ids}"

    group_name = ecs_task.cfn_stack_name
    Rails.logger.info "[EventBridgeSchedule] Clear all schedules in #{group_name}"
    SgFargateRails::EventBridgeSchedule.delete_all!(group_name)

    Rails.logger.info "[EventBridgeSchedule] Register schedules in #{group_name}"
    SgFargateRails::EventBridgeSchedule.convert(Rails.application.config_for('eventbridge_schedules')).each do |schedule|
      Rails.logger.info "[EventBridgeSchedule] Register schedule #{schedule.name} in #{group_name}"
      # TODO: この辺で AWS の API Limit などのエラーが発生するとスケジュールが消えたままとなるので、エラーの内容に応じてリトライなどのエラー処理が必要
      schedule.create_run_task(
        group_name: group_name,
        cluster_arn: ecs_task.cluster_arn,
        task_definition_arn: ecs_task.task_definition_arn,
        network_configuration: {
          awsvpc_configuration: {
            assign_public_ip: 'ENABLED',
            security_groups: ecs_task.security_group_ids,
            subnets: ecs_task.public_subnet_ids,
          },
        }
      )
    end
  end

  if defined?(::DelayedCronJob)
    require 'sg_fargate_rails/delayed_cron_job_utility'

    desc 'Refresh Delayed Cron Jobs'
    task refresh_delayed_cron_jobs: :environment do
      Rails.logger.info('[refresh_delayed_cron_jobs] refresh begin...')
      SgFargateRails::DelayedCronJobScheduler.refresh_cron_jobs!
      Rails.logger.info('[refresh_delayed_cron_jobs] refresh end.')
    end

    desc 'List Delayed Cron Jobs'
    task list_delayed_cron_jobs: :environment do
      SgFargateRails::DelayedCronJobUtility.formatted_cron_jobs.each do |formatted_cron_job|
        puts formatted_cron_job
        puts "\n"
      end
    end
  end
end
