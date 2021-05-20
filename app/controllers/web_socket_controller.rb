class WebSocketController < ApplicationController
  def index
    @auction = Auction.new
  end

  private

  def auction_params
    params.require(:auction).permit(:domain_name, :starts_at, :ends_at)
  end
end
