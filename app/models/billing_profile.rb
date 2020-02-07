require 'countries'

class BillingProfile < ApplicationRecord
  alias_attribute :country_code, :alpha_two_country_code

  validates :name, presence: true
  validates :country_code, presence: true
  validates :vat_code, uniqueness: { scope: :user_id }, allow_blank: true

  validates :name, :vat_code, :street, :city, :postal_code, safe_value: true

  belongs_to :user, optional: true
  after_update :mirror_address_to_attached_invoices

  scope :orphaned, -> { where(user_id: nil) }

  def user_name
    if user
      user.display_name
    else
      I18n.t('billing_profiles.orphaned')
    end
  end

  def address
    country_name = Countries.name_from_alpha2_code(country_code)
    postal_code_with_city = [postal_code, city].join(' ')
    [street, postal_code_with_city, country_name].compact.join(', ')
  end

  def vat_rate
    return Countries.vat_rate_from_alpha2_code(country_code) if country_code == 'EE'
    return BigDecimal('0') if vat_code.present?

    Countries.vat_rate_from_alpha2_code(country_code)
  end

  def self.create_default_for_user(user_id)
    return if find_by(user_id: user_id)

    user = User.find(user_id)

    billing_profile = new(user: user, country_code: user.country_code, name: user.display_name)
    billing_profile.save!

    billing_profile
  end

  def unfinished_offers
    offers = []
    Offer.where(billing_profile_id: id).find_each do |offer|
      offers << offer if offer.auction.result&.invoice.blank?
    end
    offers
  end

  def deletable?
    return true unless unfinished_offers.any?

    errors.add :name, I18n.t('billing_profiles.in_use_by_offer')
    false
  end

  def mirror_address_to_attached_invoices
    return unless Invoice.with_billing_profile(billing_profile_id: id).any?

    Invoice.with_billing_profile(billing_profile_id: id).find_each do |invoice|
      next if invoice.paid?

      invoice.update_billing_address
      invoice.save!
    end
  end
end
