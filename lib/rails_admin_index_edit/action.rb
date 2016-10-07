module RailsAdmin
  module Config
    module Actions
      class IndexEdit < Base
        RailsAdmin::Config::Actions.register(self)

        # Is the action acting on the root level (Example: /admin/contact)
        register_instance_option :root? do
          false
        end

        register_instance_option :collection? do
          true
        end

        # Is the action on an object scope (Example: /admin/team/1/edit)
        register_instance_option :member? do
          false
        end

        register_instance_option :route_fragment do
          'index_edit'
        end

        register_instance_option :controller do
          Proc.new do |klass|
            @conf = ::RailsAdminIndexEdit::Configuration.new @abstract_model
            @model = @abstract_model.model

            if request.get?
              @objects = list_entries(@model_config, :index, nil, nil)
              @objects.sort! { |a,b| a.lft <=> b.lft } if @objects and @objects.first and @objects.first.respond_to?(:lft)
              render action: @action.template_name

            elsif request.post?
              @object = @model.where(id: params[params['model_name']]['id']).first
              if @object
                @object.update_attributes(params.require(params['model_name']).permit(@conf.options[:fields].keys))
                _fields = params.require(params['model_name']).permit(@conf.options[:fields].keys).to_hash.keys.map(&:to_sym)
                properties = @model_config.list.with(controller: self, view: self, object: @object).visible_fields
                properties.select! { |p| _fields.include?(p.name.to_sym) }
                render partial: "rails_admin/main/index_edit_cell", locals: {field: properties.first, form: nil}

              else
                render nothing: true
              end

            end
          end
        end

        register_instance_option :link_icon do
          'icon-list-alt'
        end

        register_instance_option :http_methods do
          [:get, :post]
        end
      end
    end
  end
end
