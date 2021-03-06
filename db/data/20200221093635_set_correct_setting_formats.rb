class SetCorrectSettingFormats < ActiveRecord::Migration[6.0]
  def up
    boolean_settings = %w[require_phone_confirmation voog_site_fetching_enabled]
    integer_settings = %w[auction_minimum_offer payment_term registration_term
                          ban_length ban_number_of_strikes
                          invoice_reminder_in_days wishlist_size domain_registration_reminder]
    string_settings = %w[auction_currency default_country invoice_issuer check_api_url check_sms_url
                         check_tara_url auction_duration auctions_start_at voog_api_key
                         voog_site_url]
    hash_settings = %w[violations_count_regulations_link terms_and_conditions_link]
    arr_settings = %w[wishlist_supported_domain_extensions]

    Setting.all.each do |stng|
      next if stng.value_format.present?

      stng.value_format = 'boolean' if boolean_settings.include? stng.code
      stng.value_format = 'integer' if integer_settings.include? stng.code
      stng.value_format = 'string' if string_settings.include? stng.code
      stng.value_format = 'hash' if hash_settings.include? stng.code
      stng.value_format = 'array' if arr_settings.include? stng.code

      if stng.save
        puts "#{stng.code} data format set to: '#{stng.value_format}'"
      else
        puts "Failed to set data format for '#{stng.code}'"
      end
    end
  end

  def down
  end
end
