class CreateFriends < ActiveRecord::Migration
  def self.up
    create_table :friends do |t|
      t.integer  :user_id,    :null => false
      t.integer  :friend_id,  :null => false
      t.datetime :created_at, :null => false
    end
  end

  def self.down
    drop_table :friends
  end
end
