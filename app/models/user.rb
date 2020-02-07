require 'identity_code'

class User < ApplicationRecord
  PARTICIPANT_ROLE = 'participant'.freeze
  ADMINISTATOR_ROLE = 'administrator'.freeze
  ROLES = %w[administrator participant].freeze

  ESTONIAN_COUNTRY_CODE = 'EE'.freeze
  TARA_PROVIDER = 'tara'.freeze

  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :confirmable,
         :timeoutable

  alias_attribute :country_code, :alpha_two_country_code

  validates :identity_code, uniqueness: { scope: :alpha_two_country_code }, allow_blank: true
  validate :identity_code_must_be_valid_for_estonia, if: proc { |user|
    user.country_code.present? && user.identity_code.present?
  }
  validates :mobile_phone, presence: true, unless: proc { |user|
    user.provider == TARA_PROVIDER
  }
  validates :mobile_phone, format: { with: /\A\+[1-9]{1}[0-9]{3,14}\z/ }, unless: proc { |user|
    user.provider == TARA_PROVIDER
  }

  validates :given_names, :surname, safe_value: true

  validates :given_names, presence: true
  validates :surname, presence: true
  validate :participant_must_accept_terms_and_conditions

  has_many :billing_profiles, dependent: :nullify
  has_many :payment_orders, dependent: :nullify
  has_many :offers, dependent: :nullify
  has_many :results, dependent: :nullify
  has_many :invoices, dependent: :nullify
  has_many :bans, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy

  scope :subscribed_to_daily_summary, -> { where(daily_summary: true) }

  scope :participant, -> { where(roles: [PARTICIPANT_ROLE]) }
  scope :with_billing_profiles, lambda {
    includes(:billing_profiles).where.not(billing_profiles: { user_id: nil })
  }

  def identity_code_must_be_valid_for_estonia
    return if IdentityCode.new(country_code, identity_code).valid?

    errors.add(:identity_code, I18n.t(:is_invalid))
  end

  def participant_must_accept_terms_and_conditions
    return if terms_and_conditions_accepted_at.present?

    errors.add(:terms_and_conditions, I18n.t('users.must_accept_terms_and_conditions'))
  end

  def accepts_terms_and_conditions=(acceptance)
    acceptance_as_bool = ActiveRecord::Type::Boolean.new.cast(acceptance)
    new_terms_and_conditions_accepted_at = if acceptance_as_bool
                                             terms_and_conditions_accepted_at || Time.now.utc
                                           end
    self.terms_and_conditions_accepted_at = new_terms_and_conditions_accepted_at
  end

  def accepts_terms_and_conditions
    terms_and_conditions_accepted_at.present?
  end

  def display_name
    "#{given_names} #{surname}"
  end

  def role?(role)
    roles.include?(role)
  end

  def deletable?
    invoices&.issued&.blank?
  end

  def signed_in_with_identity_document?
    provider == TARA_PROVIDER && uid.present?
  end

  def requires_phone_number_confirmation?
    if Setting.find_by(code: 'require_phone_confirmation').retrieve
      return false if signed_in_with_identity_document?
      return false if phone_number_confirmed?

      true
    else
      false
    end
  end

  def requires_captcha?
    !signed_in_with_identity_document?
  end

  def phone_number_confirmed?
    mobile_phone_confirmed_at.present?
  end

  def banned?
    Ban.where(user_id: id).valid.any?
  end

  def longest_ban
    Ban.valid.where(user_id: id).order(valid_until: :desc).first
  end

  # Make sure that notifications are send asynchronously
  def send_devise_notification(notification, *args)
    I18n.with_locale(locale) do
      devise_mailer.send(notification, self, *args).deliver_later
    end
  end

  def tampered_with?(omniauth_hash)
    uid_from_hash = omniauth_hash['uid']
    provider_from_hash = omniauth_hash['provider']

    begin
      uid != uid_from_hash ||
        provider != provider_from_hash ||
        country_code != uid_from_hash.slice(0..1) ||
        identity_code != uid_from_hash.slice(2..-1) ||
        given_names != omniauth_hash.dig('info', 'first_name') ||
        surname != omniauth_hash.dig('info', 'last_name')
    end
  end

  def self.from_omniauth(omniauth_hash)
    uid = omniauth_hash['uid']
    provider = omniauth_hash['provider']

    User.find_or_initialize_by(provider: provider, uid: uid) do |user|
      user.given_names = omniauth_hash.dig('info', 'first_name')
      user.surname = omniauth_hash.dig('info', 'last_name')
      if provider == TARA_PROVIDER
        user.country_code = uid.slice(0..1)
        user.identity_code = uid.slice(2..-1)
      end
    end
  end
end
