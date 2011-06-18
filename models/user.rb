class User < ActiveRecord::Base


  def self.division_hash
    {
      :screen_name       => 0,
      :name              => 1,
      :location          => 2,
      :description       => 3,
      :profile_image_url => 4,
      :url               => 5,
      :protected         => 6
    }
  end

end
