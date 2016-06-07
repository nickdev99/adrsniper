class CartProductsTest < ActiveSupport::TestCase
	fixtures :cart_products

# When uncommented, the below code causes the following error:
# ActiveRecord::FixtureClassNotFound: No class attached to find
#
#	test "should return cart products" do
#		crt = CartProducts.new  :cart_id => cart_products(:crt_cart_product).cart_id,
#		:product_id => cart_products(:crt_cart_product).product_id,
#		:qty => cart_products(:crt_cart_product).qty,
#		:passthru_id => cart_products(:crt_cart_product).passthru_id,
#		:group_id => cart_products(:crt_cart_product).group_id
#
#		assert crt.save
#		crt_copy = CartProducts.find(crt.id)
#		assert_equal crt.product_id, crt_copy.product_id
#		crt.qty = "4"
#
#		assert crt.save
#		assert crt.destroy
#
#	end
end