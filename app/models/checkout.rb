# frozen_string_literal: true

# Methods from the Adyen API Library for Ruby are defined here in the model and
# called from `CheckoutsController`.

# Note that certain values have been hard-coded for simplicity (i.e., you'll
# want to obtain some data from external resources or generate them at runtime).

require 'adyen-ruby-api-library'

class Checkout
  class << self
    # Makes the /paymentMethods request
    # https://docs.adyen.com/api-explorer/#/PaymentSetupAndVerificationService/paymentMethods
    def get_payment_methods(country = 'FI', locale = 'fi_FI')
      adyen_client.checkout.payment_methods(
        {
          countryCode: country,
          shopperLocale: locale,
          merchantAccount: ENV['MERCHANT_ACCOUNT'],
          channel: 'Web'
        }
      )
    end

    # Makes the /payments request
    # https://docs.adyen.com/api-explorer/#/PaymentSetupAndVerificationService/payments
    def make_payment(payment_method, browser_info, remote_ip, payment_info)
      request = {
        merchantAccount: ENV['MERCHANT_ACCOUNT'],
        channel: 'Web', # required
        amount: {
          currency: payment_info[:currency],
          value: payment_info[:amount] # value in minor units
        },
        reference: payment_info[:reference], # required
        additionalData: {
          # required for 3ds2 native flow
          allow3DS2: true
        },
        origin: 'http://localhost:8080', # required for 3ds2 native flow
        browserInfo: browser_info, # required for 3ds2
        shopperIP: remote_ip, # required by some issuers for 3ds2
        returnUrl: "http://localhost:8080/api/handleShopperRedirect?orderRef=#{payment_info[:reference]}", # required for 3ds2 redirect flow
        paymentMethod: payment_method # required
      }

      puts request.to_json

      response = adyen_client.checkout.payments(request)

      puts response.to_json

      response
    end

    # Makes the /payments/details request
    # https://docs.adyen.com/api-explorer/#/PaymentSetupAndVerificationService/payments/details
    def submit_details(details)
      response = adyen_client.checkout.payments.details(details)
      puts response.to_json
      response
    end

    private

    def adyen_client
      @adyen_client ||= instantiate_checkout_client
    end

    def instantiate_checkout_client
      adyen = Adyen::Client.new
      adyen.api_key = ENV['API_KEY']
      adyen.env = :test
      adyen
    end
  end
end
