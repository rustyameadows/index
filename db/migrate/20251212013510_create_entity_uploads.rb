class CreateEntityUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :entity_uploads do |t|
      t.references :entity, null: false, foreign_key: true
      t.references :upload, null: false, foreign_key: true

      t.timestamps
    end

    add_index :entity_uploads, [:entity_id, :upload_id], unique: true
  end
end
