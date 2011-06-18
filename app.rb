# -*- encoding: UTF-8 -*-
require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'active_support/core_ext'
require 'slim'
require 'mysql2'
PATH_BASE = File.join(File.dirname(__FILE__))
$LOAD_PATH.push File.join(PATH_BASE, 'models')
require 'user'
require 'activist'
require 'activity'

configure do
  config_dir   = File.join(PATH_BASE, 'config')
  db_config    = YAML.load_file(File.join(config_dir, 'database.yml'))
  ActiveRecord::Base.establish_connection(db_config['development'])
end

get '/' do
  #"Hello World!"
  @activities = Activity.order('id desc').all
  @users_hash = {}
  User.where('id IN (?)', @activities.map{|a| a.user_id}).all.each do |user|
    @users_hash[user.id] = user
  end
  slim :index
end

get '/oauth/callback' do
  '/oauth/callback'
end

get '/:screen_name/timeline/feed' do |screen_name|
  ':screen_name/timeline/feed'
end

get '/:screen_name/timeline' do |screen_name|
  ':screen_name/timeline'
end

get '/:screen_name/feed' do |screen_name|
  ':screen_name/feed'
end

get '/:screen_name' do |screen_name|
  ':screen_name'
end

