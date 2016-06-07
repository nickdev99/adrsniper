class WatchConfig < ActiveRecord::Base
    has_many :watches, :foreign_key => 'cfg_hash', :primary_key => 'cfg_hash'
end
