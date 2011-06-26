class OptimizeTables < ActiveRecord::Migration
  def self.up
    add_index :users,      :screen_name
    add_index :activities, :user_id
    add_index :friends,    :user_id
  end

  def self.down
    remove_index :users,      :screen_name
    remove_index :activities, :user_id
    remove_index :friends,    :user_id
  end
end
