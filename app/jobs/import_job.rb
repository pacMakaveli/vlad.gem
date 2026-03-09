# Background job for processing imports
class ImportJob < ApplicationJob
  queue_as :default

  def perform(import_batch_id)
    import_batch = ImportBatch.find(import_batch_id)
    ImportProcessor.new(import_batch).process
  end
end
