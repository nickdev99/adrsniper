class Users::RegistrationsController < Devise::RegistrationsController
    #before_action :check_invite, only: :create
    #after_filter :close_invite, only: :create
    attr_accessor :allow_reg, :invite

    def base_user_params
        return [:first_name, :last_name, :email, :password, :password_confirmation,
                :addr_line1, :addr_line2, :city, :state, :postal_code, :country_code,
                :sms_enabled, :sms_phone_number, :group_id
        ]
    end

    def account_update_params
        allowed_params = base_user_params
        allowed_params << :current_password
        params.require(:user).permit(*allowed_params)
    end

    def sign_up_params
        allowed_params = base_user_params
        params.require(:user).permit(*allowed_params)
    end

    def new
        @open_reg = open_reg?
        puts "---------wlalls-------------"
        puts @open_reg
        puts "---------wlalls-------------"
        super
    end

    def delete
        puts "Someone tried to TOTALLY DELETE their account! This is not allowed."
    end

    def delete
        puts "Someone tried to TOTALLY DELETE their account! This is not allowed."
    end

    private
    def check_invite
        allow_reg = false
        open_regs = WdwToolsConfig.find_by(:key => "open_registration_slots")
        int_val = open_regs.value.to_i
        if int_val > 0
            open_regs.value = int_val -= 1
            open_regs.save
            allow_reg = true
        else
            flash[:error] = "We're sorry, open registration is not available at this time. Please use an invite code."
        end

        if !allow_reg and params.has_key?(:invite_code) and !params[:invite_code].empty?
            invite = ::Invitation.find_by(:code => params[:invite_code])
            if !invite.nil?
                allow_reg = true
                self.invite = invite
            else
                flash[:error] = "The supplied invite code is invalid or expired. Please try another."
            end
        end

        self.allow_reg = allow_reg

        if !allow_reg
            render :action => "new"
        end
    end

    def close_invite
        puts "\n\n\nALLOW_REG IS #{self.allow_reg} and resource is #{resource}\n\n\n"
        if !self.invite.nil?
            self.invite.redeemer_id = resource.id
            self.invite.redeemed_timestamp = resource.created_at
            self.invite.save
            puts "invitee successfully registered"
        else
            puts "successful open reg; no invite needed."
        end
    end
end
