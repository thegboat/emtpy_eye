module EmptyEye
  class Base < ActiveRecord::Base
    
    self.abstract_class = true
    
    def save(*args)
      super unless valid?
      primary_record = if new_record?
        table_extended_with.primary.shard.new
      else
        table_extended_with.primary.shard.find_by_id(id)
      end
      table_extended_with.each do |ext|
        next if ext.primary
        assoc = primary_record.send(ext.table) || primary_record.send("build_#{ext.table}")
        primary_record.send("#{ext.table}=", assoc)
      end
      primary_record.attributes = attributes
      rtn = primary_record.save
      self.id = primary_record.id if new_record?
      reload
      rtn
    end
    
    def primary_shard
      self.class.primary_shard
    end
    
    def table_extended_with
      self.class.extended_with
    end
    
    class << self
      def mti_class?
        extended_with.any?
      end
    
      def extend_table(primary_table = nil)
        self.primary_key = "id"
        raise(EmptyEye::AlreadyExtended, "extend table method already invoked") if mti_class?
        primary_table = table_name if primary_table.nil? and descends_from_active_record?
        self.table_name = compute_view_name 
        extended_with.with_table(primary_table)
        yield extended_with if block_given?
        create_view
        true
      end

      def extended_with
        @extended_with ||= superclass_extensions || ViewExtensionCollection.new(self)
      end
    
      private
    
      def compute_view_name
        to_s.underscore.pluralize
      end
    
      def create_view
        connection.execute("DROP VIEW #{table_name}") rescue nil
        connection.execute(extended_with.create_view_sql)
      end
    
      def superclass_extensions
        superclass.extended_with.dup unless descends_from_active_record?
      end
    end
    
  end
end