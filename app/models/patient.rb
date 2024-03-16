class Patient < ActiveRecord::Base
  extend Enumerize
  include Export

  # reserve the id；center_id和project_id暂时保留了，但应该不能直接显示出中心名和项目名（在export.rb的values_for_export函数里完成了id到中文的转换）
  EXPORT_IGNORED_COLUMNS = %w(id status user_id checker_id created_at updated_at)
  COLUMN_TRANSFORMATIONS = {ID_number: :force_string,
                            phone_number_1: :force_string,
                            phone_number_2: :force_string }

  enumerize :status,
            in: {
                established:  0,
                researching:  1,
                followup:  2,
                followup_end:3,
                quit:4
            },
            predicates: true,
            scope: true

  belongs_to :project
  belongs_to :user
  belongs_to :center
  has_one :basement_assessment, dependent: :destroy
  has_one :clinical_pathology, dependent: :destroy
  has_one :reserach_completion, dependent: :destroy
  has_one :medication_completion, dependent: :destroy
  has_one :group_information, dependent: :destroy
  has_one :death_record, dependent: :destroy
  has_one :course_monitor, dependent: :destroy
  has_one :followup_monitor, dependent: :destroy
  has_one :radiation_therapy, dependent: :destroy
  has_many :adverse_events, dependent: :destroy
  has_many :courses, dependent: :destroy
  has_many :tumor_evaluations, dependent: :destroy
  has_many :radiation_therapies, dependent: :destroy
  has_many :concomitant_drugs, dependent: :destroy
  has_many :biological_sample_collections, dependent: :destroy
  has_many :followups, dependent: :destroy

  has_one :export_cache  #新增导出

  attr_accessor :center_name
  attr_accessor :overdue_courses
  attr_accessor :overdue_followups

  validates :user_id,presence: true
  validates :center_id,presence: true
  validates :project_id,presence: true
  validates :hosptalization_number,presence: true

  before_create :convertStatusToEstablished
  after_save :set_export_cache

  def convertStatusToEstablished
    self.status=0
  end

  def set_center_name
    self.center_name=self.center.name
  end

  def set_overdue_courses
    if self.status.value==1
      self.overdue_courses=self.course_monitor.overdue_course
    else
      self.overdue_courses=self.status
    end
  end

  def set_overdue_followups
    if self.status.value==2
      self.overdue_followups=self.followup_monitor.overdue_followup
    else
      self.overdue_followups=self.status
    end
  end

  private
  def set_export_cache(update_all = false)
    tables = Export::EXPORT_TABLE_NAMES
    cache = export_cache

    if cache
      if update_all
        cache.update(to_csv(tables))
      else
        cache.update(to_csv())
      end
    else
      create_export_cache(to_csv(tables))
    end
  end

  public
  def to_csv(tables = [], options = {})
    # tables &= Export::EXPORT_TABLE_NAMES
    tables = tables - ['patient']

    split, col_sep, row_sep, trans =
        options.fetch(:split, true), options.fetch(:col_sep, ','), options.fetch(:row_sep, "\n"), options.fetch(:translate, true)

    csv_op = { row_sep: nil, col_sep: col_sep }

    index = tables.find_index('operation')
    tables.insert(index + 1, 'operation_lesions') unless index.nil?

    hsh ={ 'patient' => values_for_export(trans).to_csv(csv_op) }

    tables.each do |t|
      _tmp = self.public_send(t)

      case t
        when 'operation_lesions', 'followups', 'inbodies', 'metabolisms', 'blood_samples', 'lesion_primary_sps', 'lesion_blood_sps', 'hrrs', 'basement_assessments', 'adverse_events', 'radiation_therapies', 'concomitant_drugs', 'biological_sample_collections'
            _tmp = _tmp.order('created_at desc') if t == 'followups'
            _size = _tmp.columns_for_export.size
            Export::EXPORT_LIMIT[t.to_sym].times do |i|
              vals = _tmp[i].nil? ?
                  Array.new(_size) : _tmp[i].values_for_export(trans)
              hsh["#{t.singularize}_#{i}"] = vals.to_csv(csv_op)
            end
        else
          vals = (_tmp.nil? or (_tmp.is_a?(ActiveRecord::Associations::CollectionProxy) && _tmp.empty?))?
              Array.new(t.singularize.classify.constantize.columns_for_export(false, true).size) : _tmp.values_for_export(trans)
          hsh[t] = vals.to_csv(csv_op)
      end
    end
    split ? hsh : hsh.values.join(col_sep).concat(row_sep)
  end

end
