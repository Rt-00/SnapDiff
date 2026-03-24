class MigrateToUuidV7PrimaryKeys < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    execute "PRAGMA foreign_keys = OFF"

    drop_table :diff_reports, if_exists: true
    drop_table :snapshots,    if_exists: true
    drop_table :endpoints,    if_exists: true
    drop_table :projects,     if_exists: true
    drop_table :users,        if_exists: true

    create_table :users, id: :string do |t|
      t.string   :api_token
      t.string   :email,               null: false, default: ""
      t.string   :encrypted_password,  null: false, default: ""
      t.integer  :failed_attempts,     null: false, default: 0
      t.datetime :locked_at
      t.datetime :remember_created_at
      t.datetime :reset_password_sent_at
      t.string   :reset_password_token
      t.timestamps
    end
    add_index :users, :api_token,            unique: true
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true

    create_table :projects, id: :string do |t|
      t.string :user_id, null: false
      t.string :name
      t.text   :description
      t.timestamps
    end
    add_index :projects, :user_id
    add_foreign_key :projects, :users

    create_table :endpoints, id: :string do |t|
      t.string :project_id,          null: false
      t.string :baseline_snapshot_id
      t.string :name
      t.string :url
      t.string :http_method
      t.text   :headers
      t.text   :body
      t.string :schedule
      t.timestamps
    end
    add_index :endpoints, :project_id
    add_foreign_key :endpoints, :projects

    create_table :snapshots, id: :string do |t|
      t.string   :endpoint_id, null: false
      t.string   :name
      t.text     :response_body
      t.integer  :response_time_ms
      t.integer  :status_code
      t.datetime :taken_at
      t.string   :triggered_by
      t.timestamps
    end
    add_index :snapshots, :endpoint_id
    add_foreign_key :snapshots, :endpoints

    # FK from endpoints to snapshots (circular — added after both tables exist)
    add_foreign_key :endpoints, :snapshots, column: :baseline_snapshot_id

    create_table :diff_reports, id: :string do |t|
      t.string :snapshot_a_id, null: false
      t.string :snapshot_b_id, null: false
      t.text   :diff_data
      t.string :summary
      t.timestamps
    end
    add_index :diff_reports, :snapshot_a_id
    add_index :diff_reports, :snapshot_b_id
    add_foreign_key :diff_reports, :snapshots, column: :snapshot_a_id
    add_foreign_key :diff_reports, :snapshots, column: :snapshot_b_id

    execute "PRAGMA foreign_keys = ON"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
