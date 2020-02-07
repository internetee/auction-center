class InvoiceItemGenerator
  RANGE_START = Time.zone.now - 1.month

  def self.generate! count
    count.times do
      self.new.create!
    end
  end

  def create!
    invoice = Invoice.left_outer_joins(:invoice_items).
      where(invoice_items: { invoice_id: nil }).sample
    attrs = {
        invoice: invoice,
        cents: invoice.cents,
        name: "Domain transfer code for #{invoice.result.auction.domain_name} (auction).",
        uuid: SecureRandom.uuid
    }

    item = InvoiceItem.new(attrs)
    item.save!(validate: false)
  end
end

InvoiceItemGenerator.generate! Invoice.all.count
