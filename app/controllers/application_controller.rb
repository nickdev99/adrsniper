require 'unirest'
require 'htmlentities'

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def get_from_wp(id_type, id, cpt=nil)
      r_str = "https://wdwtools.com/blog/wp-json/posts"

      if id_type == "slug"
         r_str += "?filter[name]=#{params[:slug]}"
      elsif id_type == "id"
         r_str += "/#{id}/?"
      end

      if !cpt.nil?
          r_str += "&type[]=#{cpt}"
      end

      puts "r_str: #{r_str}"
      r = Unirest.get r_str
      return r.body
  end

  def open_reg?
        open_regs = WdwToolsConfig.find_by(:key => "open_registration_slots")

        begin
            int_val = open_regs.value.to_i
        rescue
            # die if value can't be converted to an integer
            return false
        end

        if int_val > 0
            return true
        else
            return false
        end
  end

  def validate_subscription!
    if current_user.subscription_active != true
      flash[:notice] = "You must have a valid subscription to use this section of the site."
      redirect_to invoices_path
    end
  end

  def validate_product_ownership!(product_ids)
      #product_ids MUST be an array, and if any product_ids match, the user is let through.
      if product_ids.class != Array
          raise
      end

      # this is temporary until all users of the old pricing model are gone
      if current_user.subscription_active and current_user.subscription_thru > Time.now
          return true
      end

      ko_flag = true
      product_ids.each do |pid|
          if UserProduct.does_user_own?(current_user.id, pid)
              ko_flag = false
         end
      end

      if ko_flag
          flash[:notice] = "You don't own that product."
          redirect_to invoices_path
          return
      end
  end

end
