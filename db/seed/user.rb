class UserGenerator
  PROVIDER_ARRAY = ['tara', nil]

  def self.generate! count
    count.times do
      self.new.create!
    end
  end

  def create!
    User.create!(
      email: email,
      password: 'password123',
      password_confirmation: 'password123',
      alpha_two_country_code: 'US',
      identity_code: identity_code,
      given_names: given_names,
      surname: surname,
      confirmed_at: Time.zone.now - 6.months,
      created_at: Time.zone.now - 6.months,
      mobile_phone: mobile_phone,
      roles: ['participant'],
      terms_and_conditions_accepted_at: Time.zone.now - 6.months,
      uuid: SecureRandom.uuid,
      locale: 'en',
      provider: PROVIDER_ARRAY.sample
    )
  end

  def identity_code
    Faker::Number.unique.number(digits: 11)
  end

  def mobile_phone
    '+37255000001'
  end

  def given_names
    Faker::Name.first_name
  end

  def surname
    Faker::Name.last_name
  end

  def email
    Faker::Internet.unique.email
  end
end

UserGenerator.generate! 10
