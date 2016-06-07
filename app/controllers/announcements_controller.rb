class AnnouncementsController < ApplicationController

	def create
		announcement = Announcement.new(announcement_params)
		announcement.save
		flash[:success] = "Announcements created."
		redirect_to announcements_path
	end

	def new
		@announcement = Announcement.new
	end

	def update
		@announcement = Announcement.find(params[:id])
		@announcement.update(announcement_params)
		@announcement.save
		redirect_to announcements_path
	end

	def edit
		@announcement = Announcement.find(params[:id])
	end

	def destroy
		@announcement = Announcement.find(params[:id])
		@announcement.destroy
		flash[:success] = "Deleted."
		redirect_to announcements_path
	end

	def index
		@announcements = Announcement.order("id ASC")
	end

	def show
		@announcement = Announcement.find(params[:id])
	end

	def announcement_params
        params.require(:announcement).permit(:elite_only, :non_elite_only, :text, :title)
    end
end