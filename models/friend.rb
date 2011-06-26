class Friend < ActiveRecord::Base

  def self.replace(user_id, friend_ids)
    friends = Friend.where('user_id = ?', user_id).all
    old_ids = friends.map{ |f| f.friend_id }
    unfollow_ids  = old_ids - friend_ids
    following_ids = friend_ids - old_ids
    unfollow_ids.each do |friend_id|
      friends.each { |f| f.destroy if f.friend_id == friend_id }
    end
    following_ids.each do |friend_id|
      Friend.create(:user_id => user_id, :friend_id => friend_id)
    end
  end

  def self.acquire_friend_ids(access_token, user_id, cursor = -1)
    url = "http://api.twitter.com/1/friends/ids.json?id=#{user_id}&cursor=#{cursor}"
    result = access_token.get(url)
    return [] if 300 <= result.code.to_i
    begin
      json = JSON.parse(result.body)
      friend_ids = json['ids']
      if (json.has_key?('next_cursor') && 0 < json['next_cursor'].to_i)
        friend_ids << self.acquire_friend_ids(access_token, user_id, json['next_cursor'])
      end
      friend_ids.flatten!
      friend_ids.uniq!
      return friend_ids
    rescue
      return []
    end
  end

end
