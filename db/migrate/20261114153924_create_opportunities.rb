class CreateOpportunities < ActiveRecord::Migration[8.1]
  def change
    create_table :opportunities do |t|
      t.string :company, null: false
      t.string :role, null: false
      t.string :kind
      t.string :source
      t.string :status, null: false, default: "not_contacted"
      t.integer :pay_min
      t.integer :pay_max
      t.string :pay_unit, default: "yearly"
      t.string :url
      t.date :contacted_on
      t.date :follow_up_on
      t.text :notes
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    # Board columns: cards ordered within a status.
    add_index :opportunities, [ :status, :position ]
    # "Follow-ups due" queries and sorting.
    add_index :opportunities, :follow_up_on
  end
end
