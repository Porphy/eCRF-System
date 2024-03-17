class TumorMakerMed < ActiveRecord::Base
  extend Enumerize
  include Constant
  include Export

  enumerize :name, in: TUMORNAME_OPT
  enumerize :unit, in: TUMORUNIT_OPT
  belongs_to :medication_completion

  validates :medication_completion_id,presence: true
  validates :value,presence: true
  validates :sample_date,presence: true
  validates :name,presence: true
  validates :unit,presence: true

  after_save :set_export_cache

  def set_export_cache
    begin
      index = patient.tumor_maker_meds.index(self)
      _tmp = patient.tumor_maker_meds.order('created_at desc')
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
