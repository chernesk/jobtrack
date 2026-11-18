class CreateSettings < ActiveRecord::Migration[8.1]
  # One row for the whole app (it is a single-user tool). Every column has a default
  # that matches how the app behaved before this table existed, so upgrading changes
  # nothing until someone edits a setting.
  def change
    create_table :settings do |t|
      t.boolean :auto_refresh_enabled, null: false, default: true
      t.integer :auto_refresh_seconds, null: false, default: 15

      t.boolean :notifications_enabled, null: false, default: true
      t.boolean :notify_when_nothing_due, null: false, default: true
      t.boolean :hide_names, null: false, default: false
      # Blank means "use the matching environment variable, if any".
      t.string :ntfy_url
      t.string :ntfy_topic
      t.string :ntfy_token # encrypted by the model
      t.string :app_url

      t.timestamps
    end
  end
end
