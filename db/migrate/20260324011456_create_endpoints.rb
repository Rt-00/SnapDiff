class CreateEndpoints < ActiveRecord::Migration[8.1]
  def change
    create_table :endpoints do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name
      t.string :url
      t.string :http_method
      t.text :headers
      t.text :body
      t.string :schedule
      t.integer :baseline_snapshot_id

      t.timestamps
    end
  end
end
