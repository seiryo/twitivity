class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string  :screen_name, :null => false
      t.string  :name
      t.string  :location
      t.text    :description
      t.string  :profile_image_url
      t.string  :url
      t.boolean :protected,   :null => false, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
