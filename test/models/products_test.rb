class ProductTest < ActiveSupport::TestCase
	fixtures :products

	test "should return product" do
		crt = Product.new  :name => products(:crt_product).name,
		:invoice_description => products(:crt_product).invoice_description,
		:human_description => products(:crt_product).human_description,
		:has_recur => products(:crt_product).has_recur,
		:recur_every => products(:crt_product).recur_every,
		:recur_type => products(:crt_product).recur_type,
		:price_cents => products(:crt_product).price_cents,
		:elite_price_cents => products(:crt_product).elite_price_cents,
		:elite_only => products(:crt_product).elite_only,
		:elite_auto => products(:crt_product).elite_auto,
		:non_elite_only => products(:crt_product).non_elite_only,
		:max_qty => products(:crt_product).max_qty,
		:passthru_model_name => products(:crt_product).passthru_model_name

		assert crt.save
		crt_copy = Product.find(crt.id)
		assert_equal crt.invoice_description, crt_copy.invoice_description
		crt.human_description = "4d"

		assert crt.save
		assert crt.destroy

	end
end