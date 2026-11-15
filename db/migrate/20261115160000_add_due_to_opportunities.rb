class AddDueToOpportunities < ActiveRecord::Migration[8.1]
  def up
    add_column :opportunities, :due, :boolean, null: false, default: false
    add_index :opportunities, :due

    # Flag what is already due, in the app's time zone (the same rule as Opportunity.follow_up_due).
    execute <<~SQL.squish
      UPDATE opportunities SET due = TRUE
      WHERE status <> 'closed' AND follow_up_on <= #{connection.quote(Date.current)}
    SQL
  end

  def down
    remove_column :opportunities, :due
  end
end
