class RefurbishmentsController < ApplicationController
	before_action :require_admin!, :except => ["get_dates"]

	def require_admin!
		if !current_user.nil? and current_user.admin == true
			return true
		else
			raise ActionController::RoutingError.new("Not Found")
			return false
		end
	end

	def create
		refurb = Refurbishment.new(refurbishment_params)
		refurb.save
		flash[:success] = "Refurbishment created."
		redirect_to refurbishments_path
	end

	def new
		@refurbishment = Refurbishment.new
	end

	def update
		@refurbishment = Refurbishment.find(params[:id])
		@refurbishment.update(refurbishment_params)
		@refurbishment.save
		redirect_to refurbishments_path
	end

	def edit
		@refurbishment = Refurbishment.find(params[:id])
	end

	def destroy
		@refurbishment = Refurbishment.find(params[:id])
		@refurbishment.destroy
		flash[:success] = "Deleted."
		redirect_to refurbishments_path
	end

	def index
		@refurbishments = Refurbishment.order("start_date ASC")
	end
	def show
		@refurbishment = Refurbishment.find(params[:id])
	end

	def get_dates
		#@TODO: deal with multiple/historical refurb dates
		all_dates = []
		refurb = Refurbishment.where("restaurant_id = ? AND end_date > ?", params[:id], Time.now)
		if refurb.length > 0
			refurb = refurb[0]
			(refurb.start_date..refurb.end_date).each do |d|
				all_dates << d.strftime("%Y-%m-%d")
			end
		end
		render :json => all_dates
	end

	def refurbishment_params
        params.require(:refurbishment).permit(:start_date, :end_date, :restaurant_id)
    end
end