# frozen_string_literal: true

require 'json'

class CheckoutsController < ApplicationController
  def index; end

  def create
    session[:payment] = {
      country: params[:country],
      currency: params[:currency],
      amount: params[:amount],
      recurring: params[:recurring],
      reference: params[:reference]
    }

    redirect_to '/checkout/dropin'
  end

  def checkout
    @type = params[:type]
    @client_key = ENV['CLIENT_KEY']

    @country = session[:payment]['country']
    @currency = session[:payment]['currency']
    @amount = session[:payment]['amount']
    @recurring = session[:payment]['recurring']
    @reference = session[:payment]['reference']

    # The payment template (payment_template.html.erb) will be rendered with the
    # appropriate integration type (based on the params supplied).
    render 'payment_template'
  end

  def result
    @type = params[:type]
  end

  def get_payment_methods(country = 'FI', locale = I18n.locale.to_s)
    # The call to /paymentMethods will be made as the checkout page is requested.
    # The response will be passed to the front end,
    # which will be used to configure the instance of `AdyenCheckout`
    response = Checkout.get_payment_methods(country, locale)

    render json: response.response, status: response.status
  end

  def initiate_payment
    # The call to /payments will be made as the shopper selects the pay button.
    response = Checkout.make_payment(
      params['paymentMethod'],
      params['browserInfo'],
      request.remote_ip,
      {
        reference: session[:payment]['reference'],
        amount: session[:payment]['amount'],
        currency: session[:payment]['currency'],
        reference: session[:payment]['reference']
      }
    )

    render json: response.response, status: response.status
  end

  def handle_shopper_redirect
    payload = {}
    payload['details'] = {
      'redirectResult' => params['redirectResult']
    }

    response = Checkout.submit_details(payload).response

    case response['resultCode']
    when 'Authorised'
      redirect_to '/result/success'
    when 'Pending', 'Received'
      redirect_to '/result/pending'
    when 'Refused'
      redirect_to '/result/failed'
    else
      redirect_to '/result/error'
    end
  end

  def submit_additional_details
    payload = {}
    payload['details'] = params['details']
    payload['paymentData'] = params['paymentData']

    response = Checkout.submit_details(payload)

    render json: response.response, status: response.status
  end
end
