class CourseMedication < ActiveRecord::Base
  extend Enumerize
  include Constant
  include Export

  enumerize :reason_for_delay, in: DELAY_OPT
  enumerize :reason_for_change, in: DOSECHANGE_OPT

  belongs_to :course

  has_many :experimental_medications

  # validates :experimental_medication_id, presence: true
  # validates :course_id, presence: true
  validates :dose, presence: true

  after_save :set_export_cache

  def set_export_cache
    begin
      index = patient.course_medications.index(self)
      _tmp = patient.course_medications.order('created_at desc')
      _size = _tmp.columns_for_export.size
      cache = ExportCache.find_by(patient_id: patient_id)
      hsh = {}
      Export::EXPORT_LIMIT[model_name.plural.to_sym].times do |i|
        vals = _tmp[i].nil? ?
            Array.new(_size) : _tmp[i].values_for_export
        hsh["#{model_name.singular}_#{i}"] = vals.to_csv(row_sep: nil)
      end
      cache.update(hsh)
    rescue
      
    end
  end

end
