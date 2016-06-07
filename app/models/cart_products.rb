class CartProducts < ActiveRecord::Base
  belongs_to :cart
  belongs_to :product
  belongs_to :group
end
