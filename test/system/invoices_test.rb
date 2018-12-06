require 'application_system_test_case'

class InvoicesTest < ApplicationSystemTestCase
  def setup
    super

    @user = users(:participant)
    @invoice = invoices(:payable)

    travel_to Time.parse('2010-07-05 10:30 +0000')

    sign_in(@user)
  end

  def teardown
    super
  end

  def test_user_can_update_billing_profile_on_issued_invoice
    visit invoice_path(@invoice)

    assert(page.has_link?('Edit', href: edit_invoice_path(@invoice)))

    click_link_or_button('Edit')
    select('Joe John Participant', from: 'invoice[billing_profile_id]')
    click_link_or_button('Submit')

    assert_text('Updated successfully')
    assert_text('Joe John Participant')
  end
end