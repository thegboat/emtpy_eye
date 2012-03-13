module EmptyEye
  class ViewManager < ActiveRecord::Base
    self.table_name = "empty_eye_views"
    
    attr_accessor :sql
      
    def self.create_view(view_name, sql)
      if table_exists?
        manager = find_by_view_name(view_name) 
        manager ||= new(:view_name => view_name)
        manager.sql = sql
        manager.create_view
      else
        drop_view(view_name)
        execute_view(sql)
      end
    end
    
    def self.execute_view(sql)
      connection.execute(sql)
    end
    
    def self.drop_view(view_name)
      connection.execute %{DROP VIEW #{view_name}} rescue nil
    end
  
    def create_view
      return unless create_view? 
      drop_view if view_exists?
      self.version = compute_version
      save
      execute_view_sql
    end
    
    private
      
    def execute(sql)
      self.class.connection.execute(sql)
    end
    
    def ordinary_table_exists?
      self.class.connection.ordinary_table_exists?(view_name)
    end
    
    def compute_version
      Digest::MD5.hexdigest(sql)
    end
  
    def version_current?
      compute_version == version
    end
    
    def view_exists?
      self.connection.view_exists?(view_name)
    end
    
    def create_view?
      check_for_name_error
      !(version_current? and view_exists?)
    end
    
    def drop_view
      self.class.drop_view(view_name)
    end
    
    def execute_view_sql
      self.class.execute_view(sql)
    end

    #determine if what we want to name our view already exists
    def check_for_name_error
      if ordinary_table_exists?
        raise(EmptyEye::ViewNameError, "MTI view cannot be created because a table named '#{view_name}' already exists")
      end
    end
    
  end
end