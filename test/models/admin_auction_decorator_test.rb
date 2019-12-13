require 'test_helper'

class AdminAuctionDecoratorTest < ActiveSupport::TestCase
  def setup
    super

    @persisted_auction = auctions(:valid_with_offers)
    travel_to Time.parse('2010-07-05 10:30 +0000').in_time_zone
  end

  def teardown
    super

    travel_back
  end

  def test_class_methods_do_not_leak_to_auction_class
    assert(AdminAuctionDecorator.column_names.include?('highest_offer_cents'))
    assert_not(Auction.column_names.include?('highest_offer_cents'))
  end

  def test_table_names_are_the_same_as_auction
    assert_equal(AdminAuctionDecorator.table_name, Auction.table_name)
  end

  def test_with_highest_offers_scope_returns_a_relation_of_auctions
    auctions = AdminAuctionDecorator.with_highest_offers

    decorated_auction = auctions.find_by(auctions: { domain_name: 'with-offers.test' })
    assert_equal(@persisted_auction.id, decorated_auction.id)
    assert_equal(@persisted_auction.uuid, decorated_auction.uuid)
    assert_equal(@persisted_auction.domain_name, decorated_auction.domain_name)
    assert_equal(@persisted_auction.starts_at, decorated_auction.starts_at)
    assert_equal(@persisted_auction.ends_at, decorated_auction.ends_at)
  end

  def test_instance_implements_highest_price_method
    auctions = AdminAuctionDecorator.with_highest_offers
    decorated_auction = AdminAuctionDecorator.new(
      auctions.find_by(auctions: { domain_name: 'with-offers.test' })
    )
    assert_equal(Money.new(5000, ApplicationSetting.auction_currency), decorated_auction.highest_price)
  end
end
