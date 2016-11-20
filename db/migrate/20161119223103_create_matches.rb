class CreateMatches < ActiveRecord::Migration[5.0]
  def change
    create_table :matches do |t|
      t.integer :user1_id
      t.integer :user1_team_id
      t.integer :user1_goals

      t.integer :user2_id
      t.integer :user2_team_id
      t.integer :user2_goals

      t.timestamps
    end
  end
end
