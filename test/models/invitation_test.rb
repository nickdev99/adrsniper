class InvitationTest < ActiveSupport::TestCase
	fixtures :invitations

	test "should return invitations" do
		crt = Invitation.new  :code => invitations(:crt_invitation).code,
		:owner_id => invitations(:crt_invitation).owner_id,
		:redeemer_id => invitations(:crt_invitation).redeemer_id,
		:redeemed_timestamp => invitations(:crt_invitation).redeemed_timestamp,
		:sent_timestamp => invitations(:crt_invitation).dest_email

		assert crt.save
		crt_copy = Invitation.find(crt.id)
		assert_equal crt.owner_id, crt_copy.owner_id
		crt.redeemer_id = "4"

		assert crt.save
		assert crt.destroy

	end
end