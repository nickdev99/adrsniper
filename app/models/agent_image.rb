class AgentImage < ActiveRecord::Base
  belongs_to :user
  default_scope { where("deleted IS NOT true") }
end
