require 'balanced'
class BalPay
    def initialize
        #@bal_conn = Balanced.configure('ak-test-27dfG6RglplLfhJrmlqvaqWbyTCmgG5LV')
        @bal_conn = Balanced.configure('ak-prod-1aJhgKUhiKAFUOuaUh8lxjhy3syH58jkE')
        @merchant_uri = nil
    end

    def buy(user_id, prod_id, save_card, passthru_id: nil, gr: nil)
        get_user(user_id)
        get_prod(prod_id)

        if @user.has_elite
            price = @prod.human_price(true, cents: true, gr: gr)
        else
            price = @prod.human_price(false, cents: true, gr: gr)
        end

        # if we can't get a price value at this point, fail.
        if price.nil?
            return nil
        end

        inv = Invoice.new
        inv.user_id = @user.id
        inv.timestamp = Time.now
        inv.amount_cents = price
        inv.description = @prod.invoice_description
        inv.save
        cust_uri = find_customer(user_id)

        begin
            create_debit(cust_uri, inv.amount_cents, "#{@prod.invoice_description}", inv.description, nil)
            if @prod.name == "WDWTools Elite Membership"
                @user.has_elite = true
                @user.elite_thru = Time.now + 1.year
                @user.save
            end
            inv.paid = true
        rescue => exc
            inv.paid = false
            inv.save
            puts "I'M FRAKING OUT MAN"
            puts "#{exc}"
            raise
        end
        inv.save

        get_user_own(passthru_id)
        if @user_own.qty.nil?
            @user_own.qty = 1
        else
            @user_own.qty += 1
        end
        @user_own.save

        if !save_card
            clear_user_cards(@user.id)
        end
    end

    def renew(user_id)
        get_user(user_id)
        if @user.subscription_thru < (Time.now + (24*60*60)) and @user.subscription_renew == true
            inv = Invoice.new
            inv.user_id = @user.id
            inv.timestamp = Time.now
            inv.amount_cents = 955
            inv.description = "WDWTools monthly subscription renewal (#{Time.now.month}/#{Time.now.year})"
            inv.save
            begin
                create_debit(cust_uri, inv.amount_cents, "wdwtools mon recur", inv.description, nil)
                inv.paid = true
                @user.subscription_thru = @user.subscription_thru + 30.days
                @user.save
            rescue
                inv.paid = false
                inv.save
                raise
            end
            inv.save
        end
    end

    def get_user(uid)
        if @user.nil?
            @user = User.find(uid)
        end
        return @user
    end

    def get_prod(pid)
        if @prod.nil?
            @prod = Product.find(pid)
        end
        return @prod
    end

    def get_user_own(passthru_id=nil)
        if @user_own.nil?
            begin
                if passthru_id.nil?
                    @user_own = UserProduct.where!("user_id = ? and product_id = ?", @user.id, @product.id)
                else
                    @user_own = UserProduct.where!("user_id = ? and product_id = ? and passthru_id = ?", @user.id, @product.id, passthru_id)
                end
            rescue
                @user_own = UserProduct.new
                @user_own.product_id = @prod.id
                @user_own.user_id = @user.id
                if passthru_id.present?
                    @user_own.passthru_id = passthru_id
                end
            end
        end
    end

    def debit_user
        create_debit(cust_uri, 955, "wdwtools mon recur", "WDWTools.com subscription renewal", nil)
        flash[:notice] = "Account successfully charged. Thank you!"
    end

    def create_customer(uid)
        get_user(uid) 
        customer = Balanced::Customer.new.save
        customer.name = "#{@user.first_name} #{@user.last_name}"
        customer.save
        @customer_uri = PaymentMethod.save_pm('balanced_cust_uri', customer.uri, uid, customer.id)
        return customer.uri
    end

    def find_customer(uid)
        get_user(uid)
        cust_uri_row = PaymentMethod.where("key = ? AND user_id = ?", 'balanced_cust_uri', uid).take
        if !cust_uri_row.nil? and !cust_uri_row.value.empty?
            return cust_uri_row.value
        else
            return nil
        end
    end

    def tokenize_card(card_number, expiration_month, expiration_year, security_code, postal_code, user_id, name)
        puts "uid is #{user_id.inspect}"
        if expiration_year.length == 2
            expiration_year = "20" + expiration_year.to_s
        end
        @card = Balanced::Card.new(
            :card_number => card_number,
            :expiration_month => expiration_month,
            :expiration_year => expiration_year,
            :name => name,
            :security_code => security_code,
            :postal_code => postal_code,
        ).save
        PaymentMethod.save_pm('balanced_card_uri', @card.uri, user_id, @card.id)
        return @card.uri
    end

    def link_card_to_customer(cust_uri, tokenized_card_uri)
        customer = Balanced::Customer.find(cust_uri)
        card_res = customer.add_card(tokenized_card_uri)
        return card_res
    end

    def create_debit(cust_uri, amount, appears_as, description, source_uri)
        # no hold only.
        customer = Balanced::Customer.find(cust_uri)
        if appears_as.length > 22
            appears_as = appears_as[0..21]
        end
        deb_res = customer.debit(
            :on_behalf_of_uri => @merchant_uri,
            :amount => amount,
            :appears_on_statement_as => appears_as,
            :description => description,
            :source_uri => source_uri,
        )
        return deb_res
    end

    def collect_cards(uid)
        if @cards.nil?
            @cards = []
        end
        card_keys = PaymentMethod.where("user_id = ? AND key = ?", uid, 'balanced_card_uri')
        card_keys.each do |ck|
            begin
                @cards << Balanced::Card.find(ck.value)
            rescue Balanced::NotFound
                ck.destroy
                next
            end
        end
        return @cards
    end

    def clear_user_cards(uid)
        cards = collect_cards(uid)
        cards.each do |c|
            c.unstore
            PaymentMethod.where("bal_id = ?", c.id).each { |r| r.destroy }
        end
    end

    def message_bal_exc(exc, holder = nil)
        if holder.nil?
            holder = []
        end
        puts exc.to_yaml
        human_desc = exc.description[0..(exc.description.index("Your request id")-2)]
        holder << "Oops! Subscription failed. Here's the problem: #{human_desc}\n"
        #exc.extras.each {|k,v| holder << "Also, #{k} had this problem: #{v}. Please try again.\n" }
        return holder
    end

    def calc_sales()
        require 'chronic'
        require 'active_support/core_ext/numeric/time' 
        Time.zone = "America/New_York"
        Chronic.time_class = Time.zone

        puts "Asking for debits..."
        debits = Balanced::Debit.all(limit: 50)
        puts "Debits gotten."
        by_date = {}
        debits.each do |deb|
            dt = Chronic.parse(deb.created_at)
            ds = "#{dt.strftime("%B %e, %Y")}"
            if by_date[ds].nil?
                by_date[ds] = []
            end
            by_date[ds] << deb.amount
        end
       csv_string = ""
        by_date.each do |key, cent_list|
            accumulator = 0
            cent_list.each do |cents|
                accumulator += cents.to_i
            end
            dollars = accumulator/100.0
            dollars = "%.2f" % dollars
            puts "#{key}: $#{dollars}"
            csv_string += "#{key};#{dollars}\n"
        end
        sales_file = File.open('sales.csv', 'w')
        sales_file.write(csv_string)
        sales_file.close
     end
end
