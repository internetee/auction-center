class OfferGenerator

  def self.generate! count
    count.times do
      self.new.create!
    end
  end

  def create!
    auction = Auction.all.sample
    rand(6).times do
      user = rand(4) >= 2 ? nil : User.participant.with_billing_profiles.sample
      billing_profile = if user.present?
                          user.billing_profiles.sample
                        else
                          BillingProfile.orphaned.sample
                        end
      user_id = user&.id

      offer = Offer.new(
        auction: auction,
        user_id: user_id,
        cents: auction.offers.pluck(:cents).max.to_i + 1000,
        billing_profile: billing_profile,
        uuid: SecureRandom.uuid
      )
      offer.save!(validate: false)
    end
  end
end

OfferGenerator.generate! Auction.all.count - (Auction.all.count / 5)
