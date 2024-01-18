require 'csv'

module Export
  extend ActiveSupport::Concern

  # Export cache re-building needed if any of below three constants altered !!
  EXPORT_LIMIT = {
      contacts: 2, clinical_lesions: 4, operation_lesions: 4, followups: 5,
      imaging_sides: 2, img_mmg_lesions: 2, img_mri_lesions: 2, img_us_lesions: 2,
      pathology_lesions: 2, neo_cu_lesions: 4, neo_mmg_lesions: 4, neo_mri_lesions: 4,
      neo_us_lesions: 4, adj_cr_lesions: 4, adj_mdts:2,neo_mdts:2,twenty_eight_genes: 1, twenty_one_and_seven_genes: 1,
      metabolisms: 5, inbodies: 5, blood_samples: 5, blood_specs: 5, lesion_primary_sps: 5, lesion_primary_specs: 5, lesion_blood_sps: 5, lesion_blood_specs: 5,
      hrrs: 5, hrr_genetics: 5, hrr_systems: 5, hrr_germlines: 5 
  }

  #EXPORT_IGNORED_COLUMNS = %w(id user_id center_id patient_id checker_id twenty_one_gene_id created_at updated_at checked_at)
  EXPORT_IGNORED_COLUMNS = %w(id status user_id checker_id created_at updated_at) #center_id和project_id暂时保留了，但应该不能直接显示出中心名和项目名
  COLUMN_TRANSFORMATIONS = {}

  # all concerned methods that accepts tables array are assumed it contains 'patient'
  # and EXPORT_TABLE_NAMES is the all possible elements of that array
  #EXPORT_TABLE_NAMES  = %w( patient history clinical imaging neoadjuvant pathology operation twenty_one_gene adjuvant followups metabolisms inbodies blood_samples lesion_primary_sps lesion_blood_sps hrrs)
  EXPORT_TABLE_NAMES  = %w( patient )

  def self.header_for_export(tables, trans = true, limit = {})
    # tables &= EXPORT_TABLE_NAMES

    tables = tables.dup
    limit = EXPORT_LIMIT.merge limit

    tables.each_with_object([]) do |t, ob|
      klass = t.singularize.classify.constantize
      model_name = trans ? I18n.t(klass.model_name.i18n_key, scope: 'exports.models', default: klass.model_name.to_s) : klass.model_name.to_s

      case t
        when 'operation_lesions', 'followups', 'metabolisms', 'inbodies', 'blood_samples', 'lesion_primary_sps', 'lesion_blood_sps', 'hrrs'
          ob.concat self.concat_column_names(t, nil, limit[t.to_sym], trans)
        else
          ob.concat klass.columns_for_export(trans, true).map{ |r| model_name + '.' + r}
      end
    end
  end

  def self.concat_column_names(table_name_or_class, ary, cnt, trans)
    klass = Class === table_name_or_class ?
        table_name_or_class : table_name_or_class.to_s.singularize.classify.constantize
    tmp = ary.nil? ? klass.columns_for_export(trans, true) : ary

    cols = []

    prefix = trans ? I18n.t(klass.model_name.i18n_key, scope: 'exports.models', default: klass.model_name.to_s) : klass.model_name.to_s
    cnt.times do |index|
      cols.concat tmp.map { |col| prefix + (trans ? '' : '-') + (index+1).to_s + '.' + col }
    end
    cols
  end

  def self.refresh_export_cache
    Patient.find_each do |p|
      p.send :set_export_cache, true
    end
  end

  def values_for_export(trans = true, nested = true) #TODO: add max export limit, and empty values
    cols = self.class.columns_for_export

    # 检查是否存在 center_id和project_id 列，并获取其索引
    center_id_index = cols.find_index('center_id')
    project_id_index = cols.find_index('project_id')

    if trans
      vals = cols.each_with_object([]) do |col, obj|

        if col == 'center_id' && center_id_index
            # 使用 center 关联对象获取中心名称
            val = self.center&.name
        elsif col == 'project_id' && project_id_index
            # 使用 project 关联对象获取中心名称
            val = self.project&.name
        else
            val = self.send(col)
            if self.class.try(:flag_columns).try(:include?, col)
            val = self.selected_options(col) # Justin's method =.=
            val = val.join('/')
            elsif ::Enumerize::Value === val
            val = val.text
            end
        end

        val = val.gsub(/[,\r\n]/, ' ') if ::String === val

        transform = self.class::COLUMN_TRANSFORMATIONS
        case transform[col.to_sym]
          when :force_string
            val = '="' + val.to_s + '"'
        end

        obj.append val
      end
    else
      vals = self.attributes.slice(*cols).values
    end

    if nested
      nested_attributes_options.keys.each do |attr|
        limit = EXPORT_LIMIT[attr]
        if limit
          tmp = self.public_send(attr)
          size = tmp.columns_for_export(false, true).size
          limit.times do |i|
            vals += tmp[i].nil? ?
                 Array.new(size) : tmp[i].values_for_export(trans, true)
          end

        else
          vals += self.public_send(attr).values_for_export(trans, true)
        end
      end
    end

    vals
  end

  def set_export_cache
    cache = ExportCache.find_by(patient_id: patient_id)
    # TODO: assume the cache always exist
    cache.update( model_name.singular => values_for_export.to_csv(row_sep: nil))
  end

  class_methods do
    def columns_for_export(trans = false, nested = false)
      cols = column_names - self::EXPORT_IGNORED_COLUMNS

      cols = cols.map { |col| self.human_attribute_name(col) } if trans

      if nested
        nested_attributes_options.keys.each do |attr|
          limit = EXPORT_LIMIT[attr]
          klass = attr.to_s.singularize.classify.constantize
          tmp = klass.columns_for_export(trans, true)
          if limit
            cols.concat Export.concat_column_names(klass, tmp, limit, trans)
          else
            cols.concat tmp
          end
        end
      end
      cols
    end
  end
end
