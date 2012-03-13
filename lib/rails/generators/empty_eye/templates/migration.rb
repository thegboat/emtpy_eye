class CreateEmptyEyeViewsTable < ActiveRecord::Migration
  def up
    create_table :empty_eye_views, :force => true do |t|
      t.string :view_name, :null => false
      t.string :version, :limit => 32, :null => false
    end
    
    add_index :empty_eye_views, :view_name
  end
  
  def down
    drop_table :empty_eye_views  
  end
end