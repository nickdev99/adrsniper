class AdminController < ApplicationController

    def become
        if current_user.nil? or !current_user.admin
            raise ActionController::RoutingError.new('Not Found')
            return
        end
        sign_in(:user, User.find(params[:id]), {:bypass => true})
        redirect_to root_url
    end
end
