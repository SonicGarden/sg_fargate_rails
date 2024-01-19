module SgFargateRails
  class DelayedCronJobScheduler
    class << self
      def refresh_cron_jobs!
        DelayedCronJobScheduler.new.refresh_cron_jobs!
      end
    end

    def initialize
      unless defined?(::DelayedCronJob)
        raise 'DelayedCronJob not defined.'
      end
    end

    def refresh_cron_jobs!
      ActiveRecord::Base.transaction do
        destroy_cron_jobs!
        create_cron_jobs!
      end
    end

    private

      def destroy_cron_jobs!
        DelayedCronJobUtility.cron_jobs.find_each do |delayed_job|
          # NOTE: 念のため cron が設定されていることを再チェック
          if delayed_job.cron.present?
            delayed_job.destroy!
          end
        end
      end

      def create_cron_jobs!
        cron_settings.each do |_name, options|
          job_class = options[:class]
          job_class = options[:class].constantize unless job_class.is_a?(Class)

          # FIXME: queue_name は config で設定できるようにする
          args = options[:args]
          if args.blank?
            job_class.set(cron: options[:cron], queue: 'cron').perform_later
          elsif args.is_a?(Array)
            job_class.set(cron: options[:cron], queue: 'cron').perform_later(*args)
          elsif args.is_a?(Hash)
            job_class.set(cron: options[:cron], queue: 'cron').perform_later(**args)
          else
            raise 'invalid args option.'
          end
        end
      end

      def cron_settings
        @cron_settings ||= Rails.application.config_for('delayed_cron_jobs')
      end
  end
end
