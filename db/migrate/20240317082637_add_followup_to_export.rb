class AddFollowupToExport < ActiveRecord::Migration
  def change
    5.times do |index|
      add_column :export_caches, "followup_#{index}", :text
    end
  end
end
