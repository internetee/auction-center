require 'countries'

class UsersController < ApplicationController
  include Concerns::UserNotices
  before_action :authenticate_user!, only: %i[show edit update destroy edit_authwall]
  before_action :set_user, only: %i[show edit update destroy]
  before_action :set_minimum_password_length, only: %i[new edit]
  before_action :authorize_user, except: %i[new index create show edit_authwall
                                            toggle_subscription]

  # GET /users
  def index; end

  # GET /users/new
  def new
    redirect_to user_path(current_user.uuid), notice: t('.already_signed_in') if current_user
    @user = User.new
  end

  # GET /profile/edit
  def edit_authwall
    redirect_to edit_user_path(current_user.uuid)
  end

  # GET /profile/toggle_daily_subscription
  def toggle_subscription
    @user = current_user
    @user.daily_summary = !@user.daily_summary
    @user.save!
    redirect_to :auctions, notice: t('.subscription_status_toggled_flash')
  end

  # POST /users/new
  def create
    @user = User.new(create_params)

    respond_to do |format|
      if @user.save
        format.html do
          sign_in(User, @user)
          redirect_to user_path(@user.uuid), notice: t(:created)
        end

        format.json do
          sign_in(User, @user)
          render :show, status: :created, location: @user
        end
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /users/aa450f1a-45e2-4f22-b2c3-f5f46b5f906b
  def show
    authorize! :read, @user
    AuctionsChannel.broadcast_to("auctions_channel", { key: "value", other_key: "Imaginary value" })
  end

  # GET /users/aa450f1a-45e2-4f22-b2c3-f5f46b5f906b/edit
  def edit; end

  # PUT /users/aa450f1a-45e2-4f22-b2c3-f5f46b5f906b
  def update
    if valid_password?
      @user.attributes = params_for_update
      email_changed = @user.email_changed?

      respond_to do |format|
        if @user.valid?
          @user.save!

          format.html do
            redirect_to user_path(@user.uuid), notice: notification_for_update(email_changed)
          end
          format.json { render :show, status: :ok, location: @user }
        else
          format.html { render :edit }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to edit_user_path(@user.uuid), notice: t('.incorrect_password')
    end
  end

  def destroy
    respond_to do |format|
      if @user.deletable? && @user.destroy!
        format.html { redirect_to :root, notice: notification_for_delete(@user) }
      else
        format.html { redirect_to user_path(@user.uuid), notice: notification_for_delete(@user) }
      end
      format.json { head :no_content }
    end
  end

  private

  def create_params
    params.require(:user)
          .permit(:email, :password, :password_confirmation, :country_code,
                  :given_names, :surname, :mobile_phone, :accepts_terms_and_conditions,
                  :locale, :daily_summary)
  end

  def params_for_update
    update_params = params.require(:user)
                          .permit(:email, :password, :password_confirmation, :country_code,
                                  :given_names, :surname, :mobile_phone,
                                  :accepts_terms_and_conditions, :daily_summary)
    update_params.reject! { |_k, v| v.empty? }
    merge_updated_by(update_params)
  end

  def valid_password?
    @user.signed_in_with_identity_document? ||
      @user.valid_password?(params.dig(:user, :current_password))
  end

  def set_minimum_password_length
    @minimum_password_length = User.password_length.min
  end

  def set_user
    @user = User.accessible_by(current_ability).find_by!(uuid: params[:uuid])
  end

  def authorize_user
    authorize! :manage, @user
  end
end
