# -*- encoding: UTF-8 -*-
require 'rubygems'
require 'oauth'
require 'json'
require 'yaml'
require 'em-http'
require 'active_record'
#require 'active_support/core_ext'
require 'oauth/client/em_http'

require 'user'
require 'activist'
require 'activity'

module Twitivity

  class Crawler

    RATE_LIMIT_URL = 'http://api.twitter.com/1/account/rate_limit_status.json'
    LOOKUP_URL     = 'http://api.twitter.com/1/users/lookup.json'

    def initialize(config, exec_env = 'development')

      ActiveRecord::Base.establish_connection(config[exec_env])
      @db_user     = config[exec_env]['username']
      @db_password = config[exec_env]['password']
      @db_schema   = config[exec_env]['database']
      @db_host     = config[exec_env]['host']

      @consumer = OAuth::Consumer.new(
        config['oauth']['consumer_key'],
        config['oauth']['consumer_secret'],
        :site => 'http://twitter.com'
      )
      @access_token = OAuth::AccessToken.new(
        @consumer,
        config['oauth']['access_token'],
        config['oauth']['access_token_secret']
      )

      @lookup_users_limit = config['crawler']['limit']['lookup_users']
      @connection_limit   = config['crawler']['limit']['connection']
      @preserve_api_limit = config['crawler']['limit']['preserve_api']
      @user_hash          = {}
      @activist_set       = []
    end

    def start
      if _acquire_api_remaining_hits < (@preserve_api_limit + @connection_limit)
        return
      end
      activist_ids = _acquire_activists
      _acquire_user_hash(activist_ids)
      while 0 < (users = activist_ids.slice!(0, @lookup_users_limit)).size
        @activist_set << users
      end
      EventMachine.run do
        @activist_set.each do |user_ids|
          options = {
            :head => {'Content-Type' => 'application/x-www-form-urlencoded'},
            :body => {'user_id' => user_ids.join(','), 'skip_status' => 1}
          }
          http = EventMachine::HttpRequest.new(LOOKUP_URL).post(options) do |client|
            @consumer.sign!(client, @access_token)
          end
          http.callback do
            begin
              _lookup_user(http.response)
            rescue
              @activist_set = []
            end
            EventMachine.stop if _judge_stop(user_ids)
          end
          http.errback do
            EventMachine.stop if _judge_stop(user_ids)
          end
        end
        EventMachine.add_timer(10) do
          EventMachine.stop if _judge_stop
        end
      end
    end

    private

    def _acquire_api_remaining_hits
      remaining_hits = 0
      response = @access_token.get(RATE_LIMIT_URL)
      return 0 if 300 <= response.code.to_i
      res = JSON.parse(response.body)
      return res['remaining_hits'].to_i
    end

    def _lookup_user(response)
      JSON.parse(response).each do |user_hash|
        #p user_hash
        next unless Hash == user_hash.class && user_hash.has_key?('id')
        after_user  = User.make_user_from_hash(user_hash)
        before_user = @user_hash[user_hash['id']]
        unless before_user
          #p after_user
          after_user.save
          next
        end
        before_user, activities = _compare_activity(before_user, after_user)
        next unless before_user.changed?

        #p before_user
        before_user.save
        activities.each do |activity|
          #p activity
          activity.save
        end
      end
    end

    def _compare_activity(before_user, after_user)
      activities = []
      User.division_hash.each do |column, division|
        before_column = before_user.send(column)
        after_column  = after_user.send(column)
        # compare before after
        if User.division_hash[:profile_image_url] == division
          before_filename = File.basename(before_column)
          after_filename  = File.basename(after_column)
          next if before_filename == after_filename
        end
        next if before_column == after_column
        # for update
        before_user.send("#{column.to_s}=", after_user.send(column))
        next if User.division_hash[:protected] == division
        activities << Activity.new(
          :user_id  => before_user.id,
          :before   => before_column,
          :after    => after_column,
          :division => division
        )
      end
      return before_user, activities
    end

    def _make_user_from_hash(user_hash)
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

    def _judge_stop(users = nil)
      @activist_set.delete_if { |a| a.object_id == users.object_id } if users
      0 == @activist_set.size
    end

    def _acquire_user_hash(user_ids)
      User.where("id IN (?)", user_ids).all.each do |user|
        @user_hash[user.id] = user
      end
    end

    def _acquire_activists
      begin
        count = Activist.count
      rescue
        count = 0
      end

      if 0 == count
        `wget  -q http://yats-data.com/data/users_maxid.sql.bz2`
        `bzip2 -d users_maxid.sql.bz2`
        `mysql -u#{@db_username} -p#{@db_password} -h#{@db_host} #{@db_schema} < users_maxid.sql`
        `rm -f users_maxid.sql`
      end
      activist_ids = []
      Activist.limit(@lookup_users_limit * @connection_limit).all.each do |activist|
        activist_ids << activist.id
      end
      Activist.delete(activist_ids)
      activist_ids
    end

  end

end

#Twitivity::Crawler.new.start
