class AuctionGenerator
  RANGE_START = Time.zone.now - 1.month

  def self.generate! count
    count.times do
      self.new.create!
    end
  end

  def rand_time(from, to=Time.now)
    Time.at(rand_in_range(from.to_f, to.to_f))
  end

  def rand_in_range(from, to)
    rand * (to - from) + from
  end

  def date_start
    rand_time(RANGE_START)
  end

  def create!
    starts_at = date_start
    ends_at = starts_at + 1.week

    attrs = {
      domain_name: Faker::Internet.unique.domain_name,
      starts_at: starts_at,
      ends_at: ends_at,
      uuid: SecureRandom.uuid,
      remote_id: SecureRandom.uuid
    }
    auction = Auction.new(attrs)
    auction.save(validate: false)
  end
end

Faker::Internet.unique.clear
AuctionGenerator.generate! 500
