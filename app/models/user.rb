require 'identity_code'

class User < ApplicationRecord
  PARTICIPANT_ROLE = 'participant'.freeze
  ADMINISTATOR_ROLE = 'administrator'.freeze
  ROLES = %w[administrator participant].freeze

  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :confirmable

  alias_attribute :country_code, :alpha_two_country_code

  validates :identity_code, presence: true, if: proc { |user| user.country_code == 'EE' }
  validates :identity_code, uniqueness: { scope: :alpha_two_country_code }
  validates :mobile_phone, presence: true
  validates :given_names, presence: true
  validates :surname, presence: true

  validate :identity_code_must_be_valid_for_estonia

  has_many :billing_profiles, dependent: :nullify
  has_many :offers, dependent: :nullify
  has_many :results, dependent: :nullify

  def identity_code_must_be_valid_for_estonia
    return if IdentityCode.new(country_code, identity_code).valid?

    errors.add(:identity_code, I18n.t(:is_invalid))
  end

  def display_name
    "#{given_names} #{surname}"
  end

  def role?(role)
    roles.include?(role)
  end

  # Make sure that notifications are send asynchronously
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
