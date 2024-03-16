class AdverseEvent < ActiveRecord::Base
  extend Enumerize
  include Constant
  include Export

  enumerize :events, in:EVENTS_OPT
  enumerize :turnover, in:TURNOVER_OPT
  enumerize :is_related_to_drugs, in:RELAITHDRUGS_OPT

  belongs_to :patient

  validates :patient_id,presence: true
  validates :events,presence: true
  validates :occurence_date,presence: true
  after_save :set_export_cache

  def set_export_cache
    begin
      index = patient.adverse_events.index(self)
      _tmp = patient.adverse_events.order('created_at desc')
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
