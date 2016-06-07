class UserProductTest < ActiveSupport::TestCase
	fixtures :user_products

	test "should return user product" do
		crt = UserProduct.new  :user_id => user_products(:crt_user_product).user_id,
		:product_id => user_products(:crt_user_product).product_id,
		:qty => user_products(:crt_user_product).qty,
		:last_use => user_products(:crt_user_product).last_use,
		:passthru_id => user_products(:crt_user_product).passthru_id,
		:group_id => user_products(:crt_user_product).group_id

		assert crt.save
		crt_copy = UserProduct.find(crt.id)
		assert_equal crt.qty, crt_copy.qty
		crt.last_use = "4"

		assert crt.save
		assert crt.destroy

	end
end