class InvoiceTest < ActiveSupport::TestCase
	fixtures :invoices

	test "should return invoices" do
		crt = Invoice.new  :user_id => invoices(:crt_invoice).user_id,
		:timestamp => invoices(:crt_invoice).timestamp,
		:amount_cents => invoices(:crt_invoice).amount_cents,
		:description => invoices(:crt_invoice).description,
		:paid => invoices(:crt_invoice).paid,
		:payment_event_id => invoices(:crt_invoice).payment_event_id,
		:payment_method_id => invoices(:crt_invoice).payment_method_id

		assert crt.save
		crt_copy = Invoice.find(crt.id)
		assert_equal crt.timestamp, crt_copy.timestamp
		crt.amount_cents = "4"

		assert crt.save
		assert crt.destroy

	end
end