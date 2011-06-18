#!/usr/bin/ruby
PATH_BASE = File.join(File.dirname(__FILE__), '..')
LOCK_PATH = File.join(PATH_BASE, 'tmp', 'twitivity_crawler.lock')
CONF_PATH = File.join(PATH_BASE, 'config')

$LOAD_PATH.push File.join(PATH_BASE, 'lib')
$LOAD_PATH.push File.join(PATH_BASE, 'models')
require 'crawler'

exec_env = 'development'
if 0 < ARGV.size
  exec_env = ARGV.shift
end

File.open(LOCK_PATH, File::RDWR|File::CREAT, 0644) do |file|
  if file.flock(File::LOCK_EX|File::LOCK_NB)
    db_config    = YAML.load_file(File.join(CONF_PATH, 'database.yml'))
    crawl_config = YAML.load_file(File.join(CONF_PATH, 'crawler.yml'))
    config       = db_config.merge(crawl_config)
    Twitivity::Crawler.new(config, exec_env).start
    file.flock(File::LOCK_UN)
  end
end
