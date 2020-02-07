# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

filenames = %w[setting admin auction user ban billing_profile offer result invoice invoice_item]

module Seeder
  def self.seed file
    puts "Seeding #{file.titleize}"
    path = File.expand_path(File.join(Rails.root, 'db', 'seed', "#{file}.rb"))
    require path
  end
end

filenames.each { |filename| Seeder.seed(filename) }
