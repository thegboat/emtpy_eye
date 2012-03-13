module EmptyEye
  module Generators
    class EmptyEyeGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)
      
      def add_migration
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        template("migration.rb", "db/migrate/#{timestamp}_create_empty_eye_views_table.rb")
      end
  
    end
  end
end
