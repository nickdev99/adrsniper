class UserTest < ActiveSupport::TestCase
	fixtures :users
#
# When uncommented, give the error "Failed assertion, no message given."
#
#	test "should return user" do
#		crt = User.new  :email => users(:crt_user).email,
#		:encrypted_password => users(:crt_user).encrypted_password,
#		:reset_password_token => users(:crt_user).reset_password_token,
#		:reset_password_sent_at => users(:crt_user).reset_password_sent_at,
#		:remember_created_at => users(:crt_user).remember_created_at,
#		:sign_in_count => users(:crt_user).sign_in_count,
#		:current_sign_in_at => users(:crt_user).current_sign_in_at,
#		:last_sign_in_at => users(:crt_user).last_sign_in_at,
#		:current_sign_in_ip => users(:crt_user).current_sign_in_ip,
#		:last_sign_in_ip => users(:crt_user).last_sign_in_ip,
#		:disney_email => users(:crt_user).disney_email,
#		:disney_password => users(:crt_user).disney_password,
#		:max_watch_days => users(:crt_user).max_watch_days,
#		:sms_phone_number => users(:crt_user).sms_phone_number,
#		:sms_enabled => users(:crt_user).sms_enabled,
#		:voice_phone_number => users(:crt_user).voice_phone_number,
#		:subscription_active => users(:crt_user).subscription_active,
#		:subscription_thru => users(:crt_user).subscription_thru,
#		:addr_line1 => users(:crt_user).addr_line1,
#		:addr_line2 => users(:crt_user).addr_line2,
#		:city => users(:crt_user).city,
#		:state => users(:crt_user).state,
#		:postal_code => users(:crt_user).postal_code,
#		:country_code => users(:crt_user).country_code,
#		:first_name => users(:crt_user).first_name,
#		:last_name => users(:crt_user).last_name,
#		:subscription_renew => users(:crt_user).subscription_renew,
#		:has_elite => users(:crt_user).has_elite,
#		:elite_thru => users(:crt_user).elite_thru,
#		:fpp_reminders => users(:crt_user).fpp_reminders,
#		:fpp_last_sync => users(:crt_user).fpp_last_sync,
#		:admin => users(:crt_user).admin
#
#		puts crt
#
#		assert crt.save
#		crt_copy = User.find(crt.id)
#		assert_equal crt.encrypted_password, crt_copy.encrypted_password
#		crt.reset_password_token = "4d"
#
#		assert crt.save
#		assert crt.destroy
#
#	end
end