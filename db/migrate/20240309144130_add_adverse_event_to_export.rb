class AddAdverseEventToExport < ActiveRecord::Migration
  def change
  	5.times do |index|
      add_column :export_caches, "adverse_event_#{index}", :text
    end
  end
end
