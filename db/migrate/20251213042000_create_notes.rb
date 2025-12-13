class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :slug
      t.text :plain_text

      t.timestamps
    end

    add_index :notes, [:project_id, :slug], unique: true
  end
end
