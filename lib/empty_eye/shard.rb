module EmptyEye
  class Shard < ActiveRecord::Base
    self.abstract_class = true
    
    attr_accessor :mti_instance
    cattr_accessor :mti_master_class
    
    def cascade_save
      mti_instance.send(:table_extended_with).each do |ext|
        next if ext.primary
        assoc = send(ext.name)
        assoc ||= send("build_#{ext.name}")
        send("#{ext.name}=", assoc)
      end
      assign_attributes(mti_instance.attributes)
      save
      mti_instance.id = id
      mti_instance.reload
    end
  end
end