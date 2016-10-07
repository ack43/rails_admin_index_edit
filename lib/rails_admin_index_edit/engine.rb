module RailsAdminIndexEdit
  class Engine < ::Rails::Engine

    initializer "RailsAdminIndexEdit precompile hook", group: :all do |app|

      app.config.assets.precompile += %w(rails_admin/rails_admin_index_edit.js rails_admin/rails_admin_index_edit.css)
    end
    #
    # initializer 'Include RailsAdminMultipleFileUpload::Helper' do |app|
    #   ActionView::Base.send :include, RailsAdminMultipleFileUpload::Helper
    # end
  end
end
