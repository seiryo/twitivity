require 'rubygems'
require 'bundler'

Bundler.require

require './app.rb'
use Rack::Session::Cookie
run Sinatra::Application
