class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :opportunity, null: false, foreign_key: true
      t.string :kind, null: false
      t.date :occurred_on, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :activities, [ :opportunity_id, :occurred_on ]
  end
end
