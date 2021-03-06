class LinkpayController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[callback]

  def callback
    save_response
    render status: :ok, json: { status: 'ok' }
  end

  def save_response
    invoice = Invoice.find_by(id: linkpay_params[:order_reference])
    return unless invoice
    return unless PaymentOrder.supported_methods.include?('PaymentOrders::EveryPay'.constantize)

    payment_order = PaymentOrders::EveryPay.create(invoices: [invoice], user: invoice.user)

    payment_order.response = {
      order_reference: linkpay_params[:order_reference],
      payment_reference: linkpay_params[:payment_reference],
    }
    payment_order.save
    CheckLinkpayStatusJob.perform_now(payment_order.id)
  end

  def linkpay_params
    params.permit(:order_reference, :payment_reference)
  end
end
