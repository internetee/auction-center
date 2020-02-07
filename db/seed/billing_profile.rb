class BiilingProfileGenerator

  def self.generate! count
    count.times do
      self.new.create!
    end
  end

  def create!
    create_private_person! if rand(2).even?
    create_company! if rand(2).even?
    create_orphaned! if rand(2).even?
    create_omniauth_company! if rand(2).even?
  end

  def create_private_person!
    user = User.participant.sample
    name = user.display_name
    create_billing_profile!(user: user, name: name)
  end

  def create_company!
    user = User.participant.sample
    name = Faker::Company.name
    create_billing_profile!(user: user, name: name)
  end

  def create_orphaned!
    create_billing_profile!
  end

  def create_omniauth_company!
    user = User.participant.where(provider: User::TARA_PROVIDER).sample
    name = Faker::Company.name
    create_billing_profile!(user: user, name: name)
  end

  def create_billing_profile!(user: nil, name: 'Orphan profile')
    profile = BillingProfile.new(user: user,
                                 name: name,
                                 vat_code: Faker::Company.ein,
                                 street: Faker::Address.street_address,
                                 city: Faker::Address.city,
                                 postal_code: Faker::Address.zip,
                                 alpha_two_country_code: Faker::Address.country_code,
                                 uuid: SecureRandom.uuid)
    profile.save(validate: false)
  end
end

BiilingProfileGenerator.generate! User.participant.count
