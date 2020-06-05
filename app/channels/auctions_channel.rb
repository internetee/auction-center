class AuctionsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'auctions:auctions_channel'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
