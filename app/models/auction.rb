class Auction < ApplicationRecord
  after_create :find_auction_turns
  after_commit :send_new_created_auction

  validates :domain_name, presence: true
  validates :ends_at, presence: true
  validates :starts_at, presence: true

  validate :does_not_overlap
  validate :ends_at_later_than_starts_at
  validate :starts_at_cannot_be_in_the_past, on: :create

  has_many :offers, dependent: :delete_all
  has_one :result, required: false, dependent: :destroy

  scope :active, -> { where('starts_at <= ? AND ends_at >= ?', Time.now.utc, Time.now.utc) }
  scope :without_result, lambda {
    where('ends_at < ? and id NOT IN (SELECT results.auction_id FROM results)', Time.now.utc)
  }

  scope :for_period, lambda { |start_date, end_date|
    where(ends_at: start_date.beginning_of_day..end_date.end_of_day)
  }

  scope :without_offers, -> { includes(:offers).where(offers: { auction_id: nil }) }
  scope :with_offers, -> { includes(:offers).where.not(offers: { auction_id: nil }) }

  delegate :count, to: :offers, prefix: true
  delegate :size, to: :offers, prefix: true

  def send_new_created_auction
    ActionCable.server.broadcast("auctions", message: "created domain")
  end

  def does_not_overlap
    return unless starts_at && ends_at
    return unless overlaping_auctions&.exists?

    errors.add(:starts_at, 'overlaps with another auction')
    errors.add(:ends_at, 'overlaps with another auction')
  end

  def starts_at_cannot_be_in_the_past
    return unless starts_at
    return if starts_at >= Time.now.utc

    errors.add(:starts_at, 'cannot be in the past')
  end

  def highest_price
    return unless offers.any?

    offers.order(cents: :desc).limit(1).first.price
  end

  # As the name suggests, this method return the offer that is currently the highest.
  # The following case might occur:
  # Auction `auction` has two offers, A (50.00) and B (5.00). When an auction expires, offer A
  # is the winner.
  # auction.currently_winning_offer -> Offer A

  # After a few month, user who made offer A decides that he no longer
  # needs an account in the auction center, so he deletes it. Now, offer B is the winner,
  # even if the domain was already registered to the user A.
  def currently_winning_offer
    offers.where('user_id IS NOT NULL').order(cents: :desc, created_at: :asc).first
  end

  def current_price_from_user(user_id)
    offers_query = offers.where(user_id: user_id)
    offers_query.order(cents: :desc).first&.price
  end

  def offer_from_user(user_id)
    offers.where(user_id: user_id).order(cents: :desc).first
  end

  def ends_at_later_than_starts_at
    return unless starts_at && ends_at
    return if ends_at > starts_at

    errors.add(:starts_at, 'must be earlier than ends_at')
  end

  def overlaping_auctions
    dates_order = [starts_at, ends_at].sort
    sql = "domain_name = ? AND tsrange(starts_at, ends_at, '[]') && tsrange(?, ?, '[]')"
    auctions = Auction.unscoped.where(sql, domain_name, dates_order.first, dates_order.second)
    auctions = auctions.where.not(id: id) if persisted?
    auctions
  end

  def can_be_deleted?
    if valid?
      !in_progress? && !finished?
    else
      false
    end
  end

  def finished?
    if valid?
      Time.now.utc > ends_at
    else
      false
    end
  end

  def in_progress?
    if valid?
      Time.now.utc > starts_at && !finished?
    else
      false
    end
  end

  def find_auction_turns
    update(turns_count: calculate_turns_count)
  end

  def calculate_turns_count
    auctions = Auction.unscoped.where(domain_name: domain_name).where('starts_at <= ?', starts_at)
    result_statuses = auctions.order(:ends_at).map { |auction| auction.result&.status }
    return 1 unless result_statuses.present? && result_statuses.first.present?

    calculate_count(result_statuses)
  end

  def calculate_count(result_statuses)
    statuses_to_drop_count = [::Result.statuses[:domain_registered],
                              ::Result.statuses[:no_bids]]
    result_statuses = result_statuses.take(result_statuses.size - 1).insert(0, nil)
    result_statuses.reduce(0) do |sum, status|
      statuses_to_drop_count.include?(status) ? 1 : sum + 1
    end
  end
end
