class Invoice < ActiveRecord::Base
  belongs_to :user
  monetize :amount_cents
end
