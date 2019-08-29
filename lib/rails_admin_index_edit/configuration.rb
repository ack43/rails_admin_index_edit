module RailsAdminIndexEdit
  class Configuration
    def initialize(abstract_model)
      @abstract_model = abstract_model
    end

    def options
      @options ||= {
          fields: {},
          add_link: false,
          default_new_params: {}
      }.merge(config || {})
    end

    protected
    def config
      ::RailsAdmin::Config.model(@abstract_model.model).index_edit || {}
    end
  end
end


module RailsAdminEmbedEdit
  class Configuration
    def initialize(abstract_model)
      @abstract_model = abstract_model
    end

    def options
      @options ||= {
        embeds: [],
        fields: {},
        default_new_params: {}
      }.merge(config || {})
    end

    protected
    def config
      ::RailsAdmin::Config.model(@abstract_model.model).embed_edit || {}
    end
  end
end