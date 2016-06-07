class PaymentMethod < ActiveRecord::Base
  belongs_to :user

  def self.save_pm(key, val, user_id, bal_id = nil)
      begin
          update_pm(key, val, user_id)
      rescue ActiveRecord::RecordNotFound
          make_pm(key, val, user_id, bal_id)
      end
  end

  def self.make_pm(key, val, user_id, bal_id)
      pm = PaymentMethod.new
      pm.key = key
      pm.value = val
      pm.user_id = user_id
      pm.bal_id = bal_id
      pm.save
      return pm
  end

  def self.update_pm(key, val, user_id)
      pm = PaymentMethod.where("key = ? AND user_id = ?", key, user_id).take
      if !pm.nil?
          pm.value = val
          pm.save
      else
          raise ActiveRecord::RecordNotFound
      end
  end

end
