require 'balpay'
class CartsController < ApplicationController
    before_action :authenticate_user!, only: [:checkout, :checkout_pay]

    def index
        if session[:cart_obj].nil?
            cart = create_new_cart
        else
            cart = session[:cart_obj]
            puts cart.id
        end

        get_cart_contents(cart)
    end

    def get_cart_contents(cart)
        cps = CartProducts.where("cart_id = ?", cart.id)
        @show_cps = []
        @cumulative_price = Money.new(0)
        @cumulative_qty = 0
        cps.each do |cp|
            if cp.qty <= 0
                # skip objects that have had their quantities explicitly reduced to zero.
                next
            end

            passthru_desc = nil
            if cp.passthru_id.present? and cp.product.passthru_model_name.present?
                # FIXME: this is hard-coded to assume the passthru'd object is always watches.
                # done to save time.
                begin
                    w = Watch.find(cp.passthru_id)
                rescue
                    next
                end
                if w.single_day?
                    passthru_desc = "(#{w.search_time.name} at #{w.restaurant.name} on #{w.friendly_start_date})"
                else
                    passthru_desc = "(#{w.search_time.name} at #{w.restaurant.name} between #{w.friendly_start_date} and #{w.friendly_end_date})"
                end
            end

            gr = cp.group_id
            item_price = if user_signed_in? and current_user.has_elite then cp.product.human_price(true, gr: gr) else cp.product.human_price(false, gr: gr) end
            if item_price.nil?
                item_price = Money.new(0)
            end
            @cumulative_price += (item_price * cp.qty)
            @cumulative_qty += cp.qty
            @show_cps.push({
                'obj' => cp,
                'price' => item_price,
                'passthru_desc' => passthru_desc,
            })
        end
        validate_cart_contents
    end

    def validate_cart_contents
        to_del = []
        seen_ids = []
        elite_present = false
        elite_id = nil
        fl_message = "<ul>\n"
        @show_cps.each do |cp|
            seen_ids << cp['obj'].product.id
            ip = purchase_allowed(current_user, cp['obj'].product)
            if !ip[:ok?]
                fl_message += "<li>#{cp['obj'].product.name} was removed from your cart because #{purchase_small_string_lookup(ip[:why])}</li>\n"
                to_del << cp['obj'].product.id
            elsif cp['obj'].product.name == "WDWTools Elite Membership"
                elite_present = true
                elite_id = cp['obj'].product.id
            end
        end

        if elite_present and seen_ids.length > 1
            seen_ids.each do |id|
                del_from_cart(id, true, false) unless id == elite_id
            end
            flash[:error] = "Elite must be purchased by itself. Press \"Remove\" below to purchase other products."
            redirect_to carts_path
            return
        elsif !to_del.empty?
            to_del.each do |d|
                del_from_cart(d, true, false)
            end

            flash[:error] = fl_message + "</ul>\n"
            # if we did have to delete something, redirect to carts_path
            # we don't let del_from_cart do this in case we have to delete
            # multiple objects.
            redirect_to carts_path
            return
        end
    end

    def create_new_cart
       if user_signed_in?
           user = User.find(current_user.id)
       end

       cart = Cart.new

       if user.present?
           cart.user_id = user.id
       end

       cart.save
       return cart
    end

    def purchase_allowed(user, prod, passthru_id=nil)
        # this condition handles nil users.
        if user.nil?
            elite = false
        elsif user.has_elite
            elite = true
        else
            elite = false
        end

        # do not allow user to obtain more than the max quantity
        if prod.max_qty.present? and report_ownership(user, prod) >= prod.max_qty
            return {:ok? => false, :why => "max_qty"}
        end

        # special quantity calculations for products that support passthru
        if prod.passthru_model_name.present? and report_ownership_passthru(user, prod, passthru_id) > 0
            return {:ok? => false, :why => "max_qty"}
        end

        if prod.elite_only and !elite
            return {:ok? => false, :why => "elite_only"}
        elsif prod.non_elite_only and elite
            return {:ok? => false, :why => "non_elite_only"}
        end

        # if we make it down here, we won.
        return {:ok? => true, :why => "no_objection"}
   end

    def purchase_string_lookup(reason)
       if reason == "non_elite_only"
           flash[:error] = "This product is for non-elite members only. This product is probably already included in your elite membership."
       elsif reason == "elite_only"
           flash[:error] = "This product is for elite members only. Upgrade your account today!"
       elsif reason == "max_qty"
           flash[:error] = "You already own as much of this item as you can."
       end
    end

    def purchase_small_string_lookup(reason)
       if reason == "non_elite_only"
           flash[:error] = "it is for non-elite members only. This product is probably already included in your elite membership."
       elsif reason == "elite_only"
           flash[:error] = "it is for elite members only. Upgrade your account today!"
       elsif reason == "max_qty"
           flash[:error] = "you already own as much of it as you can."
       end
    end

    def report_ownership(user, prod)
        # signed out users own nothing
        if user.nil?
            return 0
        end

        u_owns = UserProduct.where("user_id = ? and product_id = ?", user.id, prod.id)

        qty = 0
        u_owns.each do |uo|
            qty += uo.qty
        end

        return qty
    end

    def report_ownership_passthru(user, prod, passthru_id)
        # FIXME: there is definitely a more elegant way to handle the passthru case.
        # not implementing it because i have to get this out today.
        #
        # signed out users own nothing
        if user.nil?
            return 0
        end

        u_owns = UserProduct.where("user_id = ? and product_id = ? AND passthru_id = ?", user.id, prod.id, passthru_id)

        qty = 0
        u_owns.each do |uo|
            qty += uo.qty
        end

        return qty
    end

    def add
        args = []
        if params[:prod_id].present?
            args.push(params[:prod_id], 'id')
        elsif params[:prod_name].present?
            args.push(params[:prod_name], 'name')
        end

        if params[:passthru_id].present? and params[:passthru_id].to_i > 0
           args.push(params[:passthru_id].to_i)
        end

        puts "calling add_to_cart with these args: #{args}"

        return add_to_cart(*args)
    end

    def add_group_code
        if params[:group_code].present?
            g = Group.find_by_code(params[:group_code])
            if g.nil?
                flash[:error] = "Sorry, we didn't recognize that group code."
                redirect_to carts_path
                return
            end
            get_cart_contents session[:cart_obj]
            @show_cps.each do |cp|
                cp = cp['obj']
                cp.group_id = g.id
                cp.save
            end
            if g.discount_type == 'pct'
                amt_string = "#{g.discount_size}%"
            else
                amt_string = "$#{g.discount_size}"
            end
            flash[:notice] = "Group #{g.name} discount applied: #{amt_string} off"
        end
        redirect_to carts_path
        return
    end

    def add_to_cart(pid, type='id', passthru_id=nil)
       if type == 'name'
           prod = Product.find_by_name(pid)
           pid = prod.id
       end

       if user_signed_in? and stop_multiple_elite_membership_purchases(Product.find(pid), current_user)
           flash[:notice] = "You're already an elite member. Renewal options will be available closer to your renewal date."
           redirect_to carts_path
           return
       end

       if prod.nil?
           prod = Product.find(pid)
       end
       ip = purchase_allowed(current_user, prod, passthru_id)
       if !ip[:ok?]
           flash[:error] = purchase_string_lookup(ip[:why])
           redirect_to :back
           return
       end

       if session[:cart_obj].nil?
           cart = create_new_cart
       else
           cart = session[:cart_obj]
       end

       args = []
       where_base = "cart_id = ? AND product_id = ?"
       if passthru_id.present?
           args.push("#{where_base} AND passthru_id = ?", cart.id, pid, passthru_id)
       else
           args.push(where_base, cart.id, pid)
       end
       cps = CartProducts.where(*args)

       if cps.empty?
           cart_line = CartProducts.new
           cart_line.product_id = pid
           cart_line.cart_id = cart.id
           if passthru_id.present?
               cart_line.passthru_id = passthru_id
           end
           begin
               cart_line.qty += 1
           rescue
               cart_line.qty = 1
           end
       else
           cart_line = cps[0]
           if (prod.max_qty.nil? and (passthru_id.blank? or cart_line.passthru_id != passthru_id or (cart_line.qty <= 0 and cart_line.passthru_id == passthru_id))) or (prod.max_qty.present? and cart_line.qty < prod.max_qty)
               cart_line.qty += 1
           elsif cart_line.passthru_id == passthru_id or (prod.max_qty.present? and cart_line.qty >= prod.max_qty)
               puts "adding flash"
               flash[:error] = "You can't add any more of that item."
           end
       end

       cart_line.save

       session[:cart_obj] = cart
       redirect_to carts_path
       return
    end

    def del
        return del_from_cart(params[:prod_id])
    end

    def del_from_cart(pid, nuke=false, redir=true)
        if session[:cart_obj].nil?
            raise "Sorry, you don't have a cart to delete from."
        end

        cart = session[:cart_obj]
        puts cart
        cps = CartProducts.where("cart_id = ? and product_id = ?", cart.id, pid)
        if cps.empty?
            return true
        end
        if cps[0].qty > 0 and !nuke
            cps[0].qty -= 1
        else
            cps[0].qty = 0
        end
        cps[0].save

        if redir
            redirect_to carts_path
        end
        return
    end

    def checkout
        if session[:cart_obj].nil?
            redirect_to carts_path
            return
        end

        cart = session[:cart_obj]
        get_cart_contents(cart)

        if @cumulative_price <= Money.new(0)
            redirect_to carts_path
            return
        end

        balp = BalPay.new
        @cards = balp.collect_cards(current_user.id)
    end

    def checkout_pay
        cart = session[:cart_obj]
        if cart.nil?
            redirect_to carts_path
            return
        end
        get_cart_contents(cart)

        balp = BalPay.new

        if params[:use_what] == "new"
            balp.get_user(current_user.id)
            begin
                cust_uri = balp.find_customer(current_user.id)
                if cust_uri.nil?
                    cust_uri = balp.create_customer(current_user.id)
                end

                # delete old cards
                balp.clear_user_cards(current_user.id)

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

            rescue => exc
                flash[:error] = balp.message_bal_exc(exc)
                render :action => 'checkout'
                return
            end
        end

        @show_cps.each do |cp|
            if stop_multiple_elite_membership_purchases(cp['obj'].product, current_user)
                next
            end
            puts "Purchasing #{cp['obj'].product.name}"
            balp.buy(current_user.id, cp['obj'].product_id, params[:save_this_card], gr: cp['obj'].group_id)
            if cp['obj'].passthru_id.present?
                w = Watch.find(cp['obj'].passthru_id)
                w.paid = true
                w.save
                m = UserMailer.watch_activated(w.user, w)
                File.open("/tmp/confirm_mails/#{w.id}_#{Time.now.to_i}_mail", "w") do |f| f.write("#{w.to_yaml}\n\nEmail: #{m}") end
                m.deliver
            end
        end

        # cart purchased; zero it out
        cart.purchased = true
        cart.save
        session[:cart_obj] = nil
        cart = nil
        session[:show_google_conv_snippet] = true

        flash[:notice] = "Thanks! Your items were successfully purchased."
        redirect_to invoices_path
        return
    end

    def stop_multiple_elite_membership_purchases(prod, user)
        if prod.name == "WDWTools Elite Membership" and user.has_elite == true
            return true
        else
            return false
        end
    end
end
