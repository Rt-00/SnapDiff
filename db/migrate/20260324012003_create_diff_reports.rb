class CreateDiffReports < ActiveRecord::Migration[8.1]
  def change
    create_table :diff_reports do |t|
      t.references :snapshot_a, null: false, foreign_key: true
      t.references :snapshot_b, null: false, foreign_key: true
      t.text :diff_data
      t.string :summary

      t.timestamps
    end
  end
end
