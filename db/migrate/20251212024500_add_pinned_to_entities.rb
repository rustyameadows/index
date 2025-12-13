class AddPinnedToEntities < ActiveRecord::Migration[8.0]
  def change
    add_column :entities, :pinned, :boolean, null: false, default: false
  end
end
