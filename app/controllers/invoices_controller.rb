require 'balpay'
class InvoicesController < ApplicationController
    before_action :authenticate_user!

    def index
        @req_invite_on_new = true
        @user = User.find(current_user.id)
        @invoices = Invoice.where("user_id = ?", current_user.id)
        balp = BalPay.new
        @cards = balp.collect_cards(current_user.id)
    end

    def new_card
    end

    def cancel_sub
        @user = User.find(current_user.id)
        @user.subscription_renew = false
        @user.save
        balp = BalPay.new
        balp.get_user(current_user.id)
        balp.clear_user_cards(current_user.id)
        flash[:notice] = "Your subscription has been canceled. Services will continue until #{@user.subscription_thru}, at which time all functionality will be disabled. We hope you come back soon."
        redirect_to root_path
    end

    def cancel_get
    end

    def message_bal_exc(exc, holder = nil)
        if holder.nil?
            holder = []
        end
        puts exc.to_yaml
        human_desc = exc.description[0..(exc.description.index("Your request id")-2)]
        holder << "Purchase failed. #{human_desc}\n"
        #exc.extras.each {|k,v| holder << "Also, #{k} had this problem: #{v}. Please try again.\n" }
        return holder
    end

    def new_sub
        user = User.find(current_user.id)
        if user.subscription_active == true and user.subscription_renew == true
            flash[:notice] = "You already have an active subscription."
            redirect_to invoices_path
            return
        elsif user.subscription_active and !user.subscription_renew
            user.subscription_renew = true
            user.save
            flash[:notice] = "Monthly renewals have been reactivated."
            redirect_to invoices_path
            return
        end
        balp = BalPay.new
        begin
            balp.new_sub(user.id)
            flash[:notice] = "Your subscription is now active! Please enjoy."
            redirect_to root_path
            return
        rescue => exc
            flash[:error] << message_bal_exc(exc)
            puts message_bal_exc(exc)
            redirect_to invoices_path
            return
        end
    end

    def add_card
        balp = BalPay.new
        balp.get_user(current_user.id)
        begin
            cust_uri = balp.find_customer(current_user.id)
            if cust_uri.nil?
                cust_uri = balp.create_customer(current_user.id)
            end
            puts "cuid = #{current_user.id.inspect}"
            card_uri = balp.tokenize_card(
                params[:cc_num],
                params[:exp_month],
                params[:exp_year],
                params[:csc],
                params[:card_billing_zip],
                current_user.id,
                params[:name_on_card],
            )
            balp.link_card_to_customer(cust_uri, card_uri)
            flash[:notice] = "Card successfully added. Thank you!"
        rescue => exc
            flash[:error] = message_bal_exc(exc)
            render :action => 'new_card'
            return
        end

        if params[:auto_sub] == "1"
            redirect_to invoices_new_sub_path
        else
            redirect_to invoices_path
        end
    end
end
