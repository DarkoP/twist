module Accounts
  class BaseController < ApplicationController
    before_filter :authenticate_user!
    before_filter :authorize_user!
    before_action :subscription_required!

    private

    def subscription_required!
      if owner? && current_account.braintree_subscription_id.blank?
        message = "You must subscribe to a plan before you can use your account."
        flash[:alert] = message
        redirect_to choose_plan_url
      end
    end

    def authorize_user!
      authenticate_user!
      unless current_account.owner == current_user || 
             current_account.users.exists?(current_user.id)
        flash[:notice] = "You are not permitted to view that account."
        redirect_to root_url(subdomain: nil)
      end
    end

    def current_account
      @current_account ||= Account.find_by(subdomain: request.subdomain)
    end
    helper_method :current_account

    def owner?
      current_account.owner == current_user
    end
    helper_method :owner?
  end
end
