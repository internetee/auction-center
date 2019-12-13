class Offer < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :auction, optional: false
  belongs_to :billing_profile, optional: false

  has_one :result, required: false, dependent: :nullify

  validates :cents, numericality: { only_integer: true, greater_than: 0 }
  validate :auction_must_be_active
  validate :must_be_higher_than_minimum_offer

  def auction_must_be_active
    active_auction = Auction.active.find_by(id: auction_id)
    return if active_auction

    errors.add(:auction, I18n.t('offers.must_be_active'))
  end

  def must_be_higher_than_minimum_offer
    minimum_offer = ApplicationSetting.auction_minimum_offer
    return if minimum_offer <= cents.to_i

    currency = ApplicationSetting.auction_currency
    minimum_offer_as_money = Money.new(minimum_offer, currency)

    errors.add(:price, I18n.t('offers.must_be_higher_than', minimum: minimum_offer_as_money))
  end

  def can_be_modified?
    auction.in_progress?
  end

  def price
    Money.new(cents, ApplicationSetting.auction_currency)
  end

  def price=(value)
    number = value.to_d
    price = Money.from_amount(number, ApplicationSetting.auction_currency)
    self.cents = price.cents
  end

  def total
    price * (1 + billing_profile.vat_rate)
  end
end
