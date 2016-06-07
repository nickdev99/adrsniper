class PaymentMethodTest < ActiveSupport::TestCase
	fixtures :payment_methods

	test "should return payment method" do
		crt = PaymentMethod.new  :user_id => payment_methods(:crt_payment_method).user_id,
		:key => payment_methods(:crt_payment_method).key,
		:value => payment_methods(:crt_payment_method).value,
		:bal_id => payment_methods(:crt_payment_method).bal_id

		assert crt.save
		crt_copy = PaymentMethod.find(crt.id)
		assert_equal crt.key, crt_copy.key
		crt.value = "4d"

		assert crt.save
		assert crt.destroy

	end
end