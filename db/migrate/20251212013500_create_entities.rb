class CreateEntities < ActiveRecord::Migration[8.0]
  def change
    create_table :entities do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category, null: false
      t.text :description
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :entities, [:project_id, :name], unique: true
  end
end
