class CreateEvaluations < ActiveRecord::Migration
  def change
    create_table :evaluations do |t|
      t.integer :assignment_id
      t.integer :user_id
      t.boolean :default

      t.timestamps null: false
    end
  end
end
