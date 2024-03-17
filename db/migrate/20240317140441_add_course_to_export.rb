class AddCourseToExport < ActiveRecord::Migration
  def change
    5.times do |index|
      add_column :export_caches, "course_#{index}", :text
    end
  end
end
