class BanGenerator
  RANGE_START = Time.zone.now - 1.month

  def self.generate! count
    users = User.participant.sample count
    users.each_with_index do |user, index|
      (index + 1).times do
        create_ban(user)
      end
    end
  end

  def self.create_ban(user)
    valid_from = rand_time(RANGE_START)
    valid_until = valid_from + 1.week
    Ban.create(user: user,
               valid_from: valid_from,
               valid_until: valid_until,
               domain_name: domain_name.sample)
  end

  def self.domain_name
    [Auction.all.sample.domain_name, nil]
  end

  def self.rand_time(from, to=Time.now)
    Time.at(rand_in_range(from.to_f, to.to_f))
  end

  def self.rand_in_range(from, to)
    rand * (to - from) + from
  end
end

BanGenerator.generate! 3
