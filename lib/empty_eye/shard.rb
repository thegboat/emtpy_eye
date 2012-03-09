module EmptyEye
  class Shard < ActiveRecord::Base
    self.abstract_class = true
    
    def cascade_save(master)
      master.send(:table_extended_with).each do |ext|
        next if ext.primary
        assoc = send(ext.name) || send("build_#{ext.name}")
        send("#{ext.name}=", assoc)
      end
      assign_attributes(master.attributes)
      save
      master.id = id
      master.reload
    end
  end
end