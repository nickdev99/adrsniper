class InvitationsController < ApplicationController
    before_action :authenticate_user!, :validate_subscription!

    def check_boss
        if !user_signed_in? or current_user.email != "jeff@deseret-tech.com"
            redirect_to invitations_path
        end
    end

    def generate_code
        return SecureRandom.urlsafe_base64(6).downcase.delete('_\-aeuio').upcase
    end

    def get_unique_code
        code = generate_code
        # limitless recursion because we have to keep trying until we hit a
        # unique code. In practice, should never recurse more than once given
        # a suitable PRNG backend.
        if !Invitation.find_by(:code => code).nil?
            code = get_unique_code
        end
        return code
    end

    def create
        check_boss
        create_num = params[:create_num].to_i
        user_ids = params[:invitation][:owner_id]

        user_ids.delete("multiselect-all")
        user_ids.delete("")

        user_ids.each do |uid|
            create_num.times do |index|
                @invitation = Invitation.new(invitation_params)
                @invitation.code = get_unique_code
                @invitation.owner_id = uid
                @invitation.save
            end
        end

        flash[:notice] = "Created invitations for users #{user_ids}"

        redirect_to invitations_path
    end

    def new
       check_boss
       @invitation = Invitation.new
    end

    def index
        @invitations = Invitation.where(owner_id: current_user.id)
        @open_reg = open_reg?
    end

    def show
        check_boss
        @invitation = Invitation.unscoped.find(params[:id])
    end

    def destroy
        check_boss
        @invitation = Invitation.unscoped.find(params[:id])
        @invitation.destroy

        redirect_to invitations_path
    end

    def update
        check_boss
        puts "no-op"
    end

    def edit
        check_boss
        @invitation = Invitation.unscoped.find(params[:id])
    end

    private
    def invitation_params
        params.require(:invitation).permit()
    end
end
