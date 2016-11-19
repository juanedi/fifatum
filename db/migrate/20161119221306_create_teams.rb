class CreateTeams < ActiveRecord::Migration[5.0]
  def change
    create_table :leagues do |t|
      t.string :name
    end

    create_table :teams do |t|
      t.string :name
      t.integer :league_id
    end
  end
end
