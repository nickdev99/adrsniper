class CartTest < ActiveSupport::TestCase
	fixtures :carts

	test "should return carts" do
		crt = Cart.new  :user_id => carts(:crt_cart).user_id,
		:bought => carts(:crt_cart).bought,
		:purchased => carts(:crt_cart).purchased

		assert crt.save
		crt_copy = Cart.find(crt.id)
		assert_equal crt.bought, crt_copy.bought
		crt.purchased = "true"

		assert crt.save
		assert crt.destroy

	end
end