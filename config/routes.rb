# frozen_string_literal: true

Rails.application.routes.draw do
  root 'checkouts#index'

  post 'checkout', to: 'checkouts#create'
  get 'checkout/:type', to: 'checkouts#checkout'

  # Payment results
  get 'result/:type', to: 'checkouts#result'

  # APIs
  post 'api/getPaymentMethods', to: 'checkouts#get_payment_methods'
  post 'api/initiatePayment', to: 'checkouts#initiate_payment'
  get 'api/handleShopperRedirect', to: 'checkouts#handle_shopper_redirect'
  post 'api/handleShopperRedirect', to: 'checkouts#handle_shopper_redirect'
  post 'api/submitAdditionalDetails', to: 'checkouts#submit_additional_details'
end
