# -*- encoding: UTF-8 -*-
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'active_support/core_ext'
require 'oauth'
require 'slim'
require 'mysql2'
PATH_BASE = File.join(File.dirname(__FILE__))
$LOAD_PATH.push File.join(PATH_BASE, 'models')
require 'user'
require 'activist'
require 'activity'
require 'friend'

configure do
  config_dir   = File.join(PATH_BASE, 'config')
  db_config    = YAML.load_file(File.join(config_dir, 'database.yml'))
  ActiveRecord::Base.establish_connection(db_config['development'])
  config = YAML.load_file(File.join(config_dir, 'twitivity.yml'))
  @@consumer_key    = config['oauth']['consumer_key']
  @@consumer_secret = config['oauth']['consumer_secret']
  @@limit = config['application']['page_limit']
end

get '/oauth/callback' do
  oauth_consumer = OAuth::Consumer.new(
    @@consumer_key, @@consumer_secret, :site => "http://twitter.com")
  request_token = OAuth::RequestToken.new(
    oauth_consumer, session[:request_token], session[:request_token_secret])
  begin
    @access_token = request_token.get_access_token(
      {},
      :oauth_token => params[:oauth_token],
      :oauth_verifier => params[:oauth_verifier])
    user = User.acquire_user_info(@access_token)
    friend_ids = Friend.acquire_friend_ids(@access_token, user.id)
    Friend.replace(user.id, friend_ids)
  rescue => @exception
    return erb %{ failed: <%= @exception.message %> }
  end
  session[:screen_name]          = user.screen_name
  session[:request_token]        = nil
  session[:request_token_secret] = nil
  redirect "/#{user.screen_name}/timeline"
end

get '/oauth/request' do
  oauth_consumer = OAuth::Consumer.new(@@consumer_key, @@consumer_secret, :site => "http://twitter.com")
  request_token  = oauth_consumer.get_request_token(
    :oauth_callback => "http://twitivity.kizakiko.biz/oauth/callback")
  session[:request_token]        = request_token.token
  session[:request_token_secret] = request_token.secret
  redirect request_token.authorize_url
end

get '/' do
  redirect "/#{params[:q]}" if params[:q]
  @activities = Activity.order('id desc').limit(@@limit).all
  @users_hash = {}
  User.where('id IN (?)', @activities.map{|a| a.user_id}).all.each do |user|
    @users_hash[user.id] = user
  end
  slim :activity
end

get '/:screen_name/timeline/feed' do |screen_name|
  @users_hash = {}
  @user = User.where('screen_name = ?', screen_name).first
  return 404 unless @user
  friend_ids = Friend.where('user_id = ?', @user.id).all.map{|f| f.friend_id}
  @activities = Activity.where('user_id IN (?)', [@user.id, friend_ids].flatten)
  @activities = @activities.order('id desc').limit(@@limit).all
  User.where('id IN (?)', @activities.map{|a| a.user_id}).all.each do |user|
    @users_hash[user.id] = user
  end
  erb :feed, :layout => false
end

get '/:screen_name/timeline' do |screen_name|
  @users_hash = {}
  @user = User.where('screen_name = ?', screen_name).first
  return 404 unless @user
  friend_ids = Friend.where('user_id = ?', @user.id).all.map{|f| f.friend_id}
  @activities = Activity.where('user_id IN (?)', [@user.id, friend_ids].flatten)
  @activities = @activities.order('id desc').limit(@@limit).all
  User.where('id IN (?)', @activities.map{|a| a.user_id}).all.each do |user|
    @users_hash[user.id] = user
  end
  slim :activity
end

get '/:screen_name/status/:activity_id' do |screen_name, activity_id|
  @users_hash = {}
  @user = User.where('screen_name = ?', screen_name).first
  return 404 unless @user
  @users_hash[@user.id] = @user
  @activities = Activity.where('id = ? AND user_id = ?', activity_id, @user.id).limit(1).all
  slim :activity
end

get '/:screen_name/feed' do |screen_name|
  @users_hash = {}
  @user = User.where('screen_name = ?', screen_name).first
  return 404 unless @user
  @users_hash[@user.id] = @user
  @activities = Activity.where('user_id = ?', @user.id).order('id desc').limit(@@limit).all
  erb :feed, :layout => false
end

get '/:screen_name' do |screen_name|
  @users_hash = {}
  @user = User.where('screen_name = ?', screen_name).first
  return 404 unless @user
  @users_hash[@user.id] = @user
  @activities = Activity.where('user_id = ?', @user.id).order('id desc').limit(@@limit).all
  slim :activity
end

helpers do

  def digest_datetime(created_at)
    now = Time.now.gmtime
    now = Time.gm(now.year, now.month, now.day, now.hour, now.min, now.sec)
    days = (now - created_at).divmod(24*60*60)
    hours = days[1].divmod(60*60)
    mins = hours[1].divmod(60)
    if     1 > days.first.to_i && 1 > hours.first.to_i && 1 > mins.first.to_i
      before = "about before #{mins.last.to_i.to_s} seconds"
    elsif  1 > days.first.to_i && 1 > hours.first.to_i
      before = "about before #{mins.first.to_i.to_s} minutes"
    elsif  1 > days.first.to_i
      before = "about before #{hours.first.to_i.to_s} hours"
    else
      before = "about #{created_at.strftime("%Y-%m-%d %H:%M:%S")}"
    end
    before
  end

  def atom_updated(created_at)
    created_at.strftime("%Y-%m-%dT%H:%M:%S+09:00")
  end

  def atom_alt(activity, user)
    "/#{user.screen_name}/status/#{activity.id}"
  end

  def atom_id(activity, user) 
    "tag:twitivity.kizakiko.biz,#{activity.created_at.strftime("%Y-%m-%d")}:#{atom_alt(activity, user)}"
  end

end
