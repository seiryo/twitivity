class CreateActivities < ActiveRecord::Migration
  def self.up
    create_table :activities do |t|
      t.integer  :user_id,    :null => false
      t.integer  :division,   :null => false
      t.text     :before,     :null => false
      t.text     :after,      :null => false
      t.datetime :created_at, :null => false
    end
  end

  def self.down
    drop_table :activities
  end
end
