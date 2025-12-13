class CreateNoteReferences < ActiveRecord::Migration[8.0]
  def change
    create_table :note_references do |t|
      t.references :note, null: false, foreign_key: true
      t.string :referent_type, null: false
      t.bigint :referent_id, null: false

      t.timestamps
    end

    add_index :note_references, [:referent_type, :referent_id]
  end
end
