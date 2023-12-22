module SgFargateRails
  class DelayedCronJobUtility
    class << self
      def refresh_cron_jobs!
        DelayedCronJobUtility.new.refresh_cron_jobs!
      end

      def cron_jobs
        Delayed::Job.where.not(cron: nil)
      end

      def formatted_cron_jobs
        cron_jobs.order(id: :asc).map { |cron_job| format(cron_job) }
      end

      def format(cron_job)
        job_data = cron_job.payload_object.job_data
        <<~TEXT
          #{cron_job.cron}
          job_class : #{job_data['job_class']}
          job_args  : #{job_data['arguments']}
          queue     : #{cron_job.queue}
          run_at    : #{cron_job.run_at.to_s}
          created_at: #{cron_job.created_at.to_s}
        TEXT
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

          args = options[:args]
          if args.blank?
            job_class.set(cron: options[:cron]).perform_later
          elsif args.is_a?(Array)
            job_class.set(cron: options[:cron]).perform_later(*args)
          elsif args.is_a?(Hash)
            job_class.set(cron: options[:cron]).perform_later(**args)
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
