class AuctionsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "auctions_channel"
  end

  def unsubscribed
  end
end
