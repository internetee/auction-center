require 'test_helper'
require 'null_offer'

class NullOfferTest < ActiveSupport::TestCase
  def setup
    super

    @null_offer = NullOffer.new
  end

  def test_responds_to_known_methods_with_nil
    assert_nil(@null_offer.user)
    assert_nil(@null_offer.user_id)
  end

  def test_raises_no_method_error_in_other_cases
    assert_raises(NoMethodError) do
      @null_offer.auction
    end

    assert_raises(NoMethodError) do
      @null_offer.cents
    end
  end
end