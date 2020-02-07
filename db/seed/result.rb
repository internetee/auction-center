class ResultGenerator

  def self.generate!
    Auction.expired.each do |auction|
      if auction.offers.count == 0
        status = 'no_bids'
        user = nil
        offer = nil
      else
        status = %w[awaiting_payment domain_registered domain_not_registered].sample
        offer = auction.offers.order(cents: :desc).limit(1).first
        user = offer.user
      end
      last_remote_status = status
      uuid = SecureRandom.uuid
      registration_code = Faker::Alphanumeric.unique.alphanumeric(number: 32)

      Result.create!(auction: auction,
                     user: user,
                     status: status,
                     last_remote_status: last_remote_status,
                     offer: offer,
                     uuid: uuid,
                     registration_code: registration_code,
                     registration_due_date: auction.ends_at + 2.weeks)
    end
  end
end

ResultGenerator.generate!
