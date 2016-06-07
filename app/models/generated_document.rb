class GeneratedDocument < ActiveRecord::Base
  belongs_to :root_document
  belongs_to :user
  belongs_to :agent_image
  default_scope { where("deleted IS NOT true") }
end
