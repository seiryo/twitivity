require 'json'
require 'oauth'
class User < ActiveRecord::Base


  def self.acquire_devision(devision)
    self.division_hash.each do |key, val|
      return key if val == devision
    end
  end

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

  def self.make_user_from_hash(user_hash)
    user = User.new(
      :screen_name       => user_hash['screen_name'],
      :name              => user_hash['name'],
      :location          => user_hash['location'],
      :description       => user_hash['description'],
      :profile_image_url => user_hash['profile_image_url'],
      :url               => user_hash['url'],
      :protected         => user_hash['protected']
    )
    user.id = user_hash['id']
    user
  end

  def self.acquire_user_info(access_token)
    url = "http://api.twitter.com/1/account/verify_credentials.json"
    result = access_token.get(url)
    return [] if 300 <= result.code.to_i
    begin
      user_hash = JSON.parse(result.body)
      if (user_hash.has_key?('id') && 0 < user_hash['id'])
        user = self.find(user_hash['id'])
        unless user
          user = self.make_user_from_hash(user_hash)
          user.save
        end
        return user
      end
      raise
    rescue
      raise
    end
  end

end
