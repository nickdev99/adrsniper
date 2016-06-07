class UserProduct < ActiveRecord::Base
  belongs_to :user
  belongs_to :product

  def self.does_user_own?(user_id, product_id)
      if User.find(user_id).has_elite and Product.find(product_id).elite_auto
          return true
      end

      user_own = UserProduct.where("user_id = ? and product_id = ? and qty > 0", user_id, product_id)
      if user_own.present?
          return true
      else
          return false
      end
  end

end
