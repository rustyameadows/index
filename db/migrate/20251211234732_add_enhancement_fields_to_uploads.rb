class AddEnhancementFieldsToUploads < ActiveRecord::Migration[8.0]
  def change
    add_reference :uploads, :parent_upload, foreign_key: { to_table: :uploads }
    add_column :uploads, :processing_metadata, :jsonb, null: false, default: {}
  end
end
