require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  def setup
    @subject = Setting.new
  end

  def test_required_fields
    assert_not(@subject.valid?)

    assert_equal(["can't be blank"], @subject.errors[:code])
    assert_equal(["can't be blank"], @subject.errors[:value])
    assert_equal(["can't be blank"], @subject.errors[:description])

    @subject.code = 'some_setting'
    @subject.value = 'true'
    @subject.description = 'Some unused setting'

    assert(@subject.valid?)
  end

  def test_code_must_be_unique
    @subject.code = 'some_setting'
    @subject.value = 'true'
    @subject.description = 'Some unused setting'

    @subject.save

    new_subject = @subject.dup

    assert_not(new_subject.valid?)
    assert_equal(['has already been taken'], new_subject.errors[:code])
  end

  def test_class_methods_are_shorthand_for_values
    assert_equal('EUR', Setting.auction_currency)
    assert_equal(500, Setting.auction_minimum_offer)

    assert_equal('https://example.com', Setting.terms_and_conditions_link)
    assert_equal('EE', Setting.default_country)

    assert_equal(7, Setting.payment_term)
    assert_equal(14, Setting.registration_term)

    assert_equal(false, Setting.require_phone_confirmation)

    assert_equal(24, Setting.auction_duration)
    Setting.find_by(code: :auction_duration).update(value: 'end_of_day')
    assert_equal(:end_of_day, Setting.auction_duration)

    assert_equal(0, Setting.auctions_start_at)

    Setting.find_by(code: :auctions_start_at).update(value: 'false')
    assert_equal(false, Setting.auctions_start_at)

    assert_equal(100, Setting.ban_length)
    assert_equal(3, Setting.ban_number_of_strikes)

    assert_equal(5, Setting.domain_registration_reminder_day)
    assert_equal(1, Setting.invoice_reminder_in_days)

    assert_equal('Eesti Interneti SA, VAT number EE101286464', Setting.invoice_issuer)

    assert_equal(10, Setting.wishlist_size)
  end

  def test_accept_json_array_as_wishlist_domain_extensions_setting
    @subject = settings(:application_name)
    @subject.code = 'wishlist_supported_domain_extensions'

    @subject.value = '["ee", "pri.ee"]'
    assert @subject.valid?
    
    @subject.value = '[]'
    assert @subject.valid?

    @subject.value = '[nope]'
    assert_not @subject.valid?

    @subject.value = "spagett"
    assert_not @subject.valid?
  end

  def test_valid_format_for_wishlist_domain_extension_setting
    @subject = settings(:application_name)
    @subject.code = 'wishlist_supported_domain_extensions'
    @subject.value = '["ee", "pri.ee"]'
    assert @subject.valid?
    
    @subject.value = '["pri.ee"]'
    assert @subject.valid?

    @subject.value = '[".ee"]'
    assert @subject.valid?

    @subject.value = '["pri.ee.ee"]'
    assert_not @subject.valid?
  end
end
