module SgFargateRails
  class DelayedCronJobManager
    class << self
      def refresh!
        DelayedCronJobManager.new.refresh!
      end

      def cron_jobs
        Delayed::Job.where.not(cron: nil)
      end
    end

    def refresh!
      ActiveRecord::Base.transaction do
        destroy_cron_jobs!
        create_cron_jobs!
      end
    end

    private

      def destroy_cron_jobs!
        DelayedCronJobManager.cron_jobs.find_each do |delayed_job|
          # NOTE: 念のため cron が設定されていることを再チェック
          if delayed_job.cron.present?
            delayed_job.destroy!
          end
        end
      end

      def create_cron_jobs!
        cron_settings.each do |options|
          job_class = options[:class]
          job_class = options[:class].constantize unless job_class.is_a?(Class)

          unless job_class.is_a?(ActiveJob::Base)
            raise '対応しているジョブクラスはActiveJobのみです'
          end

          args = options[:args]
          if args.blank?
            job_class.set(cron: options[:cron]).perform_later
          elsif args.is_a?(Array)
            job_class.set(cron: options[:cron]).perform_later(*args)
          elsif args.is_a?(Hash)
            job_class.set(cron: options[:cron]).perform_later(**args)
          else
            raise 'args オプションが不正です'
          end
        end
      end

      def cron_settings
        [] # WIP: 設定ファイルからロードする
      end
  end
end
