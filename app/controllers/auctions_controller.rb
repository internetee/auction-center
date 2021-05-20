class AuctionsController < ApplicationController
  include OrderableHelper

  skip_before_action :verify_authenticity_token, only: [:cors_preflight_check]
  before_action :authorize_user

  # GET /auctions
  def index
    set_cors_header

    unpaginated_auctions = ParticipantAuctionDecorator.with_user_offers(current_user&.id)
                                                      .active
                                                      .order(orderable_array)

    respond_to do |format|
      format.html do
        @collection = unpaginated_auctions.page(params[:page])
        @auctions = @collection.map { |auction| ParticipantAuctionDecorator.new(auction) }
      end
      format.json { @auctions = unpaginated_auctions }
    end
  end

  # GET /auctions/search
  def search
    domain_name = search_params[:domain_name]

    collection = ParticipantAuctionDecorator.with_user_offers(current_user&.id)
                                            .where('domain_name ILIKE ?', "#{domain_name}%")
                                            .order(orderable_array)
                                            .accessible_by(current_ability)
                                            .page(1)

    @auctions = collection.map { |auction| ParticipantAuctionDecorator.new(auction) }
  end

  # OPTIONS /auctions
  def cors_preflight_check
    set_access_control_headers

    render plain: ''
  end

  # GET /auctions/aa450f1a-45e2-4f22-b2c3-f5f46b5f906b
  def show
    @auction = Auction.accessible_by(current_ability).find_by!(uuid: params[:uuid])
  end

  def new
    @auction = Auction.new
  end

  def create
    redis = Redis.new(url: "#{ENV.fetch("REDIS_URL")}")
    start = 0
    total = 0
    key_collection = []

    @auction = Auction.new(auction_params)
    @auction.starts_at = Time.now + 2.minute
    @auction.ends_at = Time.now + 1.day
    if @auction.save
      ActionCable.server.broadcast 'auctions_channel', content: 'Hey Redis from Auction Web Socket', domain_name: @auction.domain_name
     
      redis.set("foo", "bar")
      redis.get("foo")
      # redis.publish "auctions_channel", { domain_name: @auction.domain_name }
    end
  end

  private

  def auction_params
    params.require(:auction).permit(:domain_name)
  end

  def search_params
    search_params_copy = params.dup
    search_params_copy.permit(:domain_name)
  end

  def set_cors_header
    response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
  end

  def set_access_control_headers
    response.headers['Access-Control-Allow-Origin'] = request.headers['Origin']
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, ' \
                                                       'Authorization, Token, Auth-Token, '\
                                                       'Email, X-User-Token, X-User-Email'
    response.headers['Access-Control-Max-Age'] = '3600'
  end

  def authorize_user
    authorize! :read, Auction
  end
end
