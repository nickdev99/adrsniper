=begin


Refurb controller test tb

=begin
require 'test_helper'

class RefurbishmentsControllerTest < ActionController::TestCase

	include Devise::TestHelpers

	fixtures :refurbishments

	def setup
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in User.create(:admin)
    @user = User.new(:email => 'test@example.com', :password => 'password', :password_confirmation => 'password', :id => "1")
	@user.save
	end

	test "check refurb dates" do
		get :show, :id => 1
		assert_not_nil assigns(:refurbishment)
		assert_equal refurbishments(:crt_refurb).end_date, assigns(:refurbishment).end_date
	end
end
=end