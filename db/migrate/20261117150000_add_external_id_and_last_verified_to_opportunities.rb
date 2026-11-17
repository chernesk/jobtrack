class AddExternalIdAndLastVerifiedToOpportunities < ActiveRecord::Migration[8.1]
  def change
    add_column :opportunities, :external_id, :string
    add_column :opportunities, :last_verified_on, :date
    # Many records have no id, and SQLite allows any number of NULLs in a unique index.
    add_index :opportunities, :external_id, unique: true
  end
end
