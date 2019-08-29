require 'rails_admin/config/actions/index'

module RailsAdmin
  module Config
    module Actions
      class IndexEdit < Index
        RailsAdmin::Config::Actions.register(self)

        # # Is the action acting on the root level (Example: /admin/contact)
        # register_instance_option :root? do
        #   false
        # end
        #
        # register_instance_option :collection? do
        #   true
        # end
        #
        # # Is the action on an object scope (Example: /admin/team/1/edit)
        # register_instance_option :member? do
        #   false
        # end
        
        
        register_instance_option :breadcrumb_parent do
          if root?
            [:dashboard]
          elsif collection?
            [:index, bindings[:abstract_model]]
          elsif member?
            [:show, bindings[:abstract_model], bindings[:object]]
          end
        end


        register_instance_option :route_fragment do
          'index_edit'
        end
        register_instance_option :template_name do
          'index_edit2'
        end

        register_instance_option :controller do
          Proc.new do |klass|
            @conf = ::RailsAdminIndexEdit::Configuration.new @abstract_model
            @model = @abstract_model.model
            @fields = (@conf.options[:fields] || {}).with_indifferent_access

            if request.get?
              @objects = list_entries(@model_config, :index, nil, nil)
              @objects.sort! { |a,b| a.lft <=> b.lft } if @objects and @objects.first and @objects.first.respond_to?(:lft)
              render action: @action.template_name

            elsif request.post?
              model_name = params['model_name'].gsub("~", "_")
              @object = @model.where(id: params[model_name]['id']).first
              if @object
                fields = @conf.options[:fields].keys.map(&:to_s)
                fields = @object.fields.keys.map(&:to_s) if fields.blank?
                fields = @model_config.edit.with(controller: self, view: self, object: @object).visible_fields.select { |f| fields.include?(f.name.to_s) }
                fields = fields.collect(&:allowed_methods).flatten.uniq.collect(&:to_sym)
                fields.map!(&:to_sym)
                # fields -= restricted_fields
                fields -= [:id, :_id, :c_at, :u_at, :created_at, :updated_at, :delete]
                
                
                status = @object.update(params.require(model_name).permit(fields)) ? 200 : 422
                _fields = params.require(model_name).permit(fields).to_hash.keys.map(&:to_sym)
                properties = @model_config.edit.with(controller: self, view: self, object: @object).visible_fields
                properties.select! { |p| _fields.include?(p.name.to_sym) }
                
                field = properties.first
                if field
                  old_value = @object.try("#{field.method_name}_was")
                  current_value = @object.try(field.method_name)
                  if old_value and current_value != old_value
                    field.html_attributes ||= {}
                    field.html_attributes.merge!(data: {old_value: old_value})
                  end
                end
                render partial: "rails_admin/main/index_edit_cell", locals: {field: field, form: nil}, status: status
                
              else
                render nothing: true
              end

              
            elsif request.put?
              @object = @model.new(@conf.options[:default_new_params])
              @object.save! if @object

              @objects = list_entries(@model_config, :index, nil, nil)
              if @objects 
                if @objects.first and @objects.first.respond_to?(:lft)
                  @objects.sort! { |a,b| a.lft <=> b.lft } 
                elsif @objects.first and @objects.first.respond_to?(:c_at)
                  @objects.sort! { |a,b| a.c_at <=> b.c_at } 
                end
              end
              render partial: "rails_admin/main/index_edit_table", layout: false

            end
          end
        end

        register_instance_option :link_icon do
          'icon-list-alt'
        end

        register_instance_option :http_methods do
          [:get, :post, :put]
        end

        def restricted_fields
          [:id, :_id, :c_at, :u_at, :created_at, :updated_at, :delete]
        end

      end
    end
  end
end




module RailsAdmin
  module Config
    module Actions
      class EmbedEdit < IndexEdit
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :collection? do
          false
        end
        
        # Is the action on an object scope (Example: /admin/team/1/edit)
        register_instance_option :member? do
          true
        end

        register_instance_option :route_fragment do
          'embed_edit'
        end
        register_instance_option :template_name do
          'embed_edit'
        end

        register_instance_option :controller do
          Proc.new do |klass|
            @conf = ::RailsAdminEmbedEdit::Configuration.new @abstract_model
            @model = @abstract_model.model
            @parent = @model.find(params[:id])

            @embeds = @conf.options[:embeds].map { |e|
              if e.is_a?(Array)
                e
              elsif e.is_a?(Hash)
                [e.keys.first.to_s, e.values.first.to_s]
              else
                [e.to_s, e.to_s]
              end

            }

            @embed = @embeds.detect { |e|
              e.first.to_s == params[:embed]
            }
            @embed_name = @embed&.first&.to_s
            @embed_class = @parent.embedded_relations[@embed_name]&.klass
            @embed_abstract_model = RailsAdmin::AbstractModel.new(@embed_class)
            @embed_model_config = @embed_abstract_model&.config
            @fields = (@conf.options[:fields][@embed_name] || {}).with_indifferent_access
            if !@embed 
              @objects = []
              render action: @action.template_name

            else

              if request.get?
                @objects = @parent.try(@embed_name)
                @objects.sort! { |a,b| a.order <=> b.order } if @objects and @objects.first and @objects.first.respond_to?(:order)
                render action: @action.template_name
  
              elsif request.post?
                embed_model_name = params['embed_model_name']
                @object = @parent.try(@embed_name).where(id: params[embed_model_name]['id']).first
                if @object
                  fields = @conf.options[:fields][@embed_name]&.keys&.map(&:to_s)
                  fields = @object.fields.keys.map(&:to_s) if fields.blank?
                  fields = @embed_model_config.edit.with(controller: self, view: self, object: @object).visible_fields.select { |f| fields.include?(f.name.to_s) }
                  fields = fields.collect(&:allowed_methods).flatten.uniq.collect(&:to_sym)
                  fields.map!(&:to_sym)
                  # fields -= restricted_fields
                  fields -= [:id, :_id, :c_at, :u_at, :created_at, :updated_at, :delete]
                  
                  status = @object.update(params.require(embed_model_name).permit(fields)) ? 200 : 422
                  
                  _fields = params.require(embed_model_name).permit(fields).to_hash.keys.map(&:to_sym)
                  properties = @embed_model_config.edit.with(controller: self, view: self, object: @object).visible_fields
                  properties.select! { |p| _fields.include?(p.name.to_sym) }
                  
                  field = properties.first
                  if field
                    old_value = @object.try("#{field.name}_was")
                    current_value = @object.try(field.name)
                    if old_value and current_value != old_value
                      field.html_attributes ||= {}
                      field.html_attributes.merge!(data: {old_value: old_value})
                    end
                  end
                  render partial: "rails_admin/main/index_edit_cell", locals: {field: field, form: nil}, status: status
  
                else
                  render nothing: true
                end
              
              elsif request.put?
                @objects = @parent.try(@embed_name)
                @objects.create!(@conf.options[:default_new_params][@embed_name] || {}) if @objects

                if @objects 
                  if @objects.first and @objects.first.respond_to?(:order)
                    @objects.sort! { |a,b| a.order <=> b.order } 
                  elsif @objects.first and @objects.first.respond_to?(:c_at)
                    @objects.sort! { |a,b| a.c_at <=> b.c_at } 
                  end
                end
                render partial: "rails_admin/main/embed_edit_table", layout: false

              end # if request.get?

            end # if !embed 
          end # Proc.new do |klass|
        end # register_instance_option :controller do



        # register_instance_option :http_methods do
        #   [:get, :post, :put]
        # end
        
      end
    end
  end
end

