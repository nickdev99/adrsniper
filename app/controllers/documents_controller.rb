class DocumentsController < ApplicationController
    before_action :authenticate_user!, :has_elite!

    def has_elite!
       if !(current_user.has_elite and (current_user.elite_thru.present? and current_user.elite_thru > Time.now))
           flash[:alert] = "At this time, this area is reserved for elite members. Join today!"
           flash.keep
           redirect_to '/'
       end
    end

    def index
        @user = current_user
        @rootdocs = RootDocument.all
        @agent_images = AgentImage.where("user_id = ?", @user.id)
        @gendocs = GeneratedDocument.where("user_id = ?", @user.id)
    end

    def show_root
        rootdoc_id = params[:rootdoc_id]
        rootdoc_id = 1 unless rootdoc_id
        @doc = RootDocument.find rootdoc_id
    end

    def show_gen
        @gendocs = GeneratedDocument.where("user_id = ?", current_user.id)
        puts @gendocs.inspect
        @rootdocs = []
        rootdoc_ids = []
        @gendocs.each do |gd|
            if rootdoc_ids.include?(gd.root_document_id)
                next
            end
            rd = RootDocument.find gd.root_document_id
            rootdoc_ids << rd.id
            @rootdocs << rd
        end
    end

    def destroy
        gd = GeneratedDocument.find params[:gendoc_id]
        if current_user.id != gd.user_id
            flash[:error] = "That resource is not available."
            redirect_to '/documents'
        end
        gd.deleted = true
        gd.save
        redirect_to '/documents/show_gen'
    end

    def destroy_agent_image
        ai = AgentImage.find params[:ai_id]
        if current_user.id != ai.user_id
            flash[:error] = "That resource is not available."
            redirect_to '/documents'
        end
        ai.deleted = true
        ai.save
        redirect_to "/documents/new/#{params[:rootdoc_id]}"
    end

    def download_gen(stock = nil, filename = nil)
        if stock.nil?
            gendoc_id = params[:gendoc_id]
        else
            gendoc_id = stock
        end

        gendoc = GeneratedDocument.find gendoc_id
        extname = File.extname(gendoc.filename)[1..-1]
        mime_type = Mime::Type.lookup_by_extension(extname)

        if filename.nil?
            filename = "#{gendoc.title}.#{extname}"
        end

        if gendoc.user_id != current_user.id and stock.nil?
            flash[:error] = "Access to that resource is not available."
            redirect_to '/documents/show_gen'
        end

        gendoc_path = "#{Rails.root}/public/pdfs/#{gendoc.filename}"
        send_file(gendoc_path, {:type => mime_type, :filename => filename})
    end

    def download_stock
        rd = RootDocument.find params[:rootdoc_id]
        return download_gen(rd.stock_id, "#{rd.event_abbreviation}-#{current_user.email}.pdf")
    end

    def post_agent_image
        puts params[:uploaded_data].class
        uploaded_data = params[:uploaded_data]
        #path = "/var/www/adrsniper/public/uploaded_images/user/#{current_user.id}/"
        base_path = "#{Rails.root}/public/"
        asset_path = "uploaded_images/user/#{current_user.id}/"
        filename = "#{Time.now.to_i}#{File.extname(uploaded_data.original_filename)}"
        raw_full_path = "#{base_path}#{asset_path}#{filename}"
        asset_filename = "#{asset_path}#{filename}"

        if !File.directory?("#{base_path}#{asset_path}")
            puts "#{base_path}#{asset_path} doesn't exist, making it."
            FileUtils.mkdir_p("#{base_path}#{asset_path}")
        end

        allowed_extensions = [
            '.jpg',
            '.jpeg',
            '.png',
            '.gif',
        ]

        puts File.extname(uploaded_data.original_filename).downcase
        if !allowed_extensions.include?(File.extname(uploaded_data.original_filename).downcase)
            flash[:error] = "We don't allow that file extension. Please upload a JPG or PNG."
            redirect_to index
        end

        # write raw data

        File.open(raw_full_path, 'wb') {|f| f.write(uploaded_data.read)}

        # sanitize upload and proceed only if successful
        if clean_image(raw_full_path)
            full_path = "#{raw_full_path}_clean.png"
            agi = AgentImage.new
            thumb_image(full_path)
            agi.path = asset_filename
            agi.user = current_user
            agi.name = uploaded_data.original_filename
            agi.full_local_path = raw_full_path
            agi.save
        else
            flash[:error] = "Oops, your file doesn't seem valid. Please try again."
        end

       redirect_to '/documents/new/1'
    end

    def clean_image(full_path)
        clean_success = system("gm convert #{full_path} #{full_path}_clean.png")
        return clean_success
    end

    def thumb_image(full_path)
        thumb_success = system("gm mogrify -resize 120x120 #{full_path}_thumb.png")
        return thumb_success
    end

    def new
        rootdoc_id = params[:rootdoc_id]
        rootdoc_id = 1 unless rootdoc_id
        @agent_images = AgentImage.where("user_id = ? OR global = true", current_user.id)
        @rootdoc = RootDocument.find rootdoc_id
        if !@rootdoc.publicly_available
            if current_user.admin
                flash[:notice] = "This is a private document."
            else
                flash[:notice] = "Please try again."
                redirect_to "/documents"
            end
        end
        @gendoc = GeneratedDocument.new
    end

    def create
        rootdoc = params[:rootdoc_id]
        generate(rootdoc, params)
    end

    def generate
        rootdoc_id = params[:rootdoc_id]
        rootdoc = RootDocument.find rootdoc_id
        if !rootdoc.publicly_available
            flash[:error] = "Please try again."
            redirect_to create
        end

        #title = "#{params[:client_first_name]}#{params[:client_last_name]}-#{params[:party_date]}-#{rootdoc.event_abbreviation}"
        if params[:title].nil? or params[:title].empty?
            params[:title] = "#{Time.now}-Doc"
        end
        title = "#{params[:title]}-#{rootdoc.event_abbreviation}"
        blurb = "#{params[:line_1]}\n#{params[:line_2]}\n#{params[:line_3]}"
        ai = AgentImage.find params[:agent_image]

        if ai.user_id != current_user.id and ai.global != true
            ai = AgentImage.find 1
        end

        @gendoc = GeneratedDocument.new
        @gendoc.blurb = blurb
        @gendoc.agent_image_id = ai.id
        @gendoc.root_document_id = rootdoc.id
        @gendoc.title = title
        @gendoc.user_id = current_user.id

        current_timestamp = Time.now.to_i

        mangler_config = {
            :party_date => params[:party_date],
            :agent_image => params[:agent_image],
            :line_1 => params[:line_1],
            :line_2 => params[:line_2],
            :line_3 => params[:line_3],
            :current_timestamp => current_timestamp,
            :img_path => ai.full_local_path,
            :doc_id => rootdoc.id,
        }

        tmp_dir = "/tmp/#{current_timestamp}.#{current_user.id}.pdf_stamp/"
        FileUtils.mkdir_p tmp_dir
        Dir.chdir tmp_dir

        f = File::open("mangler_config.json", 'w')
        f.write(JSON::dump(mangler_config))
        f.close

        # this is not allowed to be broken because it will break everything else
        # because we don't want to implement sanity checks
        logger.info "Whole line: source #{Rails.root}/wdwtools-pdf-mangler/venv/bin/activate && python #{Rails.root}/wdwtools-pdf-mangler/mangle.py mangler_config.json && pdftk #{rootdoc.full_local_path} cat 1 output #{current_timestamp}_pg_1.pdf && pdftk #{current_timestamp}_pg_1.pdf stamp #{current_timestamp}_stamp_only.pdf output #{current_timestamp}_pg_1_stamped.pdf && pdftk STAMP=#{current_timestamp}_pg_1_stamped.pdf PACK=#{rootdoc.full_local_path} cat STAMP1 PACK2-end output #{current_timestamp}_complete_stamp.pdf"
        stamp_exit_status = `source #{Rails.root}/wdwtools-pdf-mangler/venv/bin/activate && python #{Rails.root}/wdwtools-pdf-mangler/mangle.py mangler_config.json && pdftk #{rootdoc.full_local_path} cat 1 output #{current_timestamp}_pg_1.pdf && pdftk #{current_timestamp}_pg_1.pdf stamp #{current_timestamp}_stamp_only.pdf output #{current_timestamp}_pg_1_stamped.pdf && pdftk STAMP=#{current_timestamp}_pg_1_stamped.pdf PACK=#{rootdoc.full_local_path} cat STAMP1 PACK2-end output #{current_timestamp}_complete_stamp.pdf`

        if stamp_exit_status != 0
            puts "Something broke horrifically. Please do something about this."
        end

        rand_string = (0...8).map { (65 + rand(26)).chr }.join
        @gendoc.filename = "#{rand_string}-#{(Time.now.to_i).to_s[-6..-1]}.pdf"
        if !File.directory? "#{Rails.root}/public/pdfs"
            FileUtils.mkdir_p "#{Rails.root}/public/pdfs"
        end
        FileUtils.copy("#{tmp_dir}#{current_timestamp}_complete_stamp.pdf", "#{Rails.root}/public/pdfs/#{@gendoc.filename}")

        FileUtils.rm_rf(tmp_dir)

        @gendoc.save
        flash[:success] = "Document successfully generated."
        redirect_to '/documents/show_gen'
    end
end
