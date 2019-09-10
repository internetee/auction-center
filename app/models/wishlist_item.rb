require 'simpleidn'

class WishlistItem < ApplicationRecord
  belongs_to :user, optional: false

  before_validation :set_domain_name_to_unicode
  before_validation :tld_autocomplete

  validates :domain_name, uniqueness: { scope: :user_id }
  validates :domain_name,
            presence: true,
            allow_blank: false,
            format: {
              # allows 1 to 61 characters with Estonian diacritic signs and 1 to 61 character
              # of the top level domain.
              with: /\A[a-z0-9\-\u00E4\u00F5\u00F6\u00FC\u0161\u017E]{1,61}\.[a-z0-9]{1,61}(\.[a-z0-9]{1,61})?\z/,
            }
  validate :valid_tld, on: :create
  validate :must_fit_in_wishlist_size, on: :create

  scope :for_user, ->(user_id) { where(user_id: user_id) }

  # A user can only have limited number to discourage people from putting the whole zone into
  # the wishlist.
  def must_fit_in_wishlist_size
    return if number_of_items_for_user < Setting.wishlist_size

    errors.add(:wishlist, I18n.t('wishlist_items.too_many_items'))
  end

  # Make sure that domain has supported TLD upon creation.
  def valid_tld
    begin
      tlds = Setting.find_by!(code: "wishlist_supported_tld").value.split("|")
      current_tld = self.domain_name.split(".", 2).last
      return if tlds.include?(current_tld)
      errors.add(:domain_name, I18n.t('is_invalid'))
    rescue StandardError
      # Ignored intentionally
    end
  end

  # Appends default tld in case no tld was added by customer beforehand.
  def tld_autocomplete
    begin
      default_tld = Setting.find_by!(code: "wishlist_supported_tld").value.split("|").first
      if !default_tld.empty?
        self.domain_name = "#{self.domain_name}.#{default_tld}" unless self.domain_name.include?(".")
      end
    rescue StandardError
      # Ignored intentionally
    end
  end

  # The fact that we store domain names as unicode is our own implementation detail and we should
  # accept either form from the user, so this should not be a validation.
  #
  # Duplicates the functionality in written in Javascript, just in case someone has it disabled
  # on their browsers.
  def set_domain_name_to_unicode
    self.domain_name = SimpleIDN.to_unicode(domain_name)
  end

  # Can safely return zero if user_id is unset, without it the whole object is invalid.
  def number_of_items_for_user
    if user_id
      WishlistItem.for_user(user_id).count
    else
      0
    end
  end
end
