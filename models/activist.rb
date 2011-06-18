class Activist < ActiveRecord::Base
  set_table_name  'users_maxid'
  set_primary_key 'internal_id'
end
