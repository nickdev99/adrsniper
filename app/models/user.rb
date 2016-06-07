class User < ActiveRecord::Base
  has_many :watches do
    def active
      self.where('enabled = true AND expired = false')
    end
  end

  has_many :invitations, :foreign_key => 'owner_id', :primary_key => 'owner_id'
  has_one :invitation, :foreign_key => 'redeemer_id', :primary_key => 'redeemer_id'

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def count_active_days(exclusions = nil)
      aw = Watch.where("user_id = ? AND expired = ? AND search_end_date > ? AND paid = ?", id, false, Time.now, true)
      if !exclusions.nil?
          exclusions.delete nil
          if exclusions.length > 0
              aw.where!("id NOT IN (?)", exclusions)
          end
      end
      day_tally = 0
      aw.each do |w|
        day_tally += w.count_days
      end
      return day_tally
  end

end