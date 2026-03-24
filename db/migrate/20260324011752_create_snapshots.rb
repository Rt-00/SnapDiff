class CreateSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :snapshots do |t|
      t.references :endpoint, null: false, foreign_key: true
      t.text :response_body
      t.integer :status_code
      t.integer :response_time_ms
      t.datetime :taken_at
      t.string :triggered_by

      t.timestamps
    end
  end
end
