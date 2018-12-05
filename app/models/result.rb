require 'auction_not_finished'
require 'auction_not_found'

class Result < ApplicationRecord
  belongs_to :auction, required: true, inverse_of: :result
  belongs_to :user, required: false
  belongs_to :offer, required: false
  belongs_to :billing_profile, required: false
  has_one :invoice, required: false, dependent: :destroy

  validates :sold, inclusion: { in: [true, false] }

  scope :pending_invoice, lambda {
    where('user_id IS NOT NULL AND sold = true AND id NOT IN (SELECT result_id FROM invoices)')
  }

  def self.create_from_auction(auction_id)
    auction = Auction.find_by(id: auction_id)

    raise(Errors::AuctionNotFound, auction_id) unless auction
    raise(Errors::AuctionNotFinished, auction_id) unless auction.finished?

    ResultCreator.new(auction_id).call
  end

  def sold?
    sold || false
  end

  def winning_offer
    offer
  end

  def send_email_to_winner
    return unless sold?

    ResultMailer.winner_email(self).deliver_later
  end
end