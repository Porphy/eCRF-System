class BiologicalSampleCollection < ActiveRecord::Base
  extend Enumerize
  include Constant
  include Export

  # enumerize :interview, in: INTERVIEW_OPT
  enumerize :biological_sample, in: BIOSAMPLE_OPT

  belongs_to :patient

  validates :biological_sample,presence: true
  validates :date_of_sampling,presence: true
  validates :sample_number,presence: true

  after_save :set_export_cache

  def set_export_cache
    begin
      index = patient.biological_sample_collections.index(self)
      _tmp = patient.biological_sample_collections.order('created_at desc')
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
