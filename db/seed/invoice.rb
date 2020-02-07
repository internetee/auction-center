class InvoiceGenerator
  RANGE_START = Time.zone.now - 1.month

  def self.generate! count
    count.times do
      self.new.create!
    end
  end

  def create!
    result = Result.with_bids.sample
    billing_profile = result.offer.billing_profile
    user = billing_profile.user

    status = case result.status
             when Result.statuses[:awaiting_payment]
               Invoice.statuses[:issued]
             when Result.statuses[:domain_registered]
               Invoice.statuses[:paid]
             else
               Invoice.statuses[:cancelled]
             end
    paid_at = status == Invoice.statuses[:paid] ? result.registration_due_date - 2.days : nil
    attrs = {
      result: result,
      user: user,
      billing_profile: billing_profile,
      cents: result.offer.cents,
      recipient: billing_profile.name,
      vat_code: Faker::Company.ein,
      street: billing_profile.street,
      city: billing_profile.city,
      state: nil,
      postal_code: billing_profile.postal_code,
      alpha_two_country_code: billing_profile.alpha_two_country_code,
      status: status,
      issue_date: result.registration_due_date - 10.days,
      due_date: result.registration_due_date - 2.days,
      uuid: SecureRandom.uuid,
      in_directo: false,
      paid_at: paid_at
    }

    invoice = Invoice.new(attrs)
    invoice.save!(validate: false)
  end
end

InvoiceGenerator.generate! 250
