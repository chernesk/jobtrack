class AddClosedReasonAndArchivedAtToOpportunities < ActiveRecord::Migration[8.1]
  def change
    add_column :opportunities, :closed_reason, :string
    add_column :opportunities, :archived_at, :datetime
    add_index :opportunities, :archived_at
  end
end
