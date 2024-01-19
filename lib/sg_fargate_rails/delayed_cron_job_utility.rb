module SgFargateRails
  class DelayedCronJobUtility
    class << self
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
  end
end
