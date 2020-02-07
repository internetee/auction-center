administrator = User.new(given_names: 'Default', surname: 'Administrator',
                         email: 'administrator@auction.test', password: 'password',
                         password_confirmation: 'password', country_code: 'EE',
                         mobile_phone: '+37250060070', identity_code: '51007050118',
                         roles: [User::ADMINISTATOR_ROLE], accepts_terms_and_conditions: true)
administrator.skip_confirmation!
administrator.save
