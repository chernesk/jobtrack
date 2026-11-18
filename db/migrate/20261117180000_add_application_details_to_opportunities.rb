class AddApplicationDetailsToOpportunities < ActiveRecord::Migration[8.1]
  def change
    add_column :opportunities, :resume_version, :string
    add_column :opportunities, :contact_name, :string
    add_column :opportunities, :application_channel, :string
  end
end
