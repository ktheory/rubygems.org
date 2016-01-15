class SqsWorker
  include Shoryuken::Worker

  # TODO: set real queue name
  # TODO: set auto_delete: true after testing
  shoryuken_options queue: 'TODO-add-real-queue', body_parser: :json, auto_delete: false

  def perform(sqs_msg, body)
    s3_objects = body['Records'].map do |record|
      [
        record['s3']['bucket']['name'],
        record['s3']['object']['key'] ]
    end

    puts "Enqueuing FastlyLogProcessor jobs for #{s3_objects.inspect}"
    ActiveRecord::Base.transaction do
      s3_objects.each do |bucket, key|
        Delayed::Job.enqueue FastlyLogProcessor.new(bucket, key), priority: PRIORITIES[:download_metrics]
      end
    end
  end
end
