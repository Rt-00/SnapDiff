class AddNameToSnapshots < ActiveRecord::Migration[8.1]
  def change
    add_column :snapshots, :name, :string
  end
end
