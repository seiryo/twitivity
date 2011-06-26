require 'rake'
require 'active_record'
require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
require 'yaml'

namespace :twitivity do

  desc "get my database config"
  task :loadconfig do
    DBconfig = YAML::load( File.open('config/database.yml') )['development']
  end

  desc "migrate my database"
  task :migrate => :loadconfig do
    migrate(DBconfig)
  end

  def migrate( config )
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection(config)
    ActiveRecord::Migrator.up "db/migrate/"
  end

end
