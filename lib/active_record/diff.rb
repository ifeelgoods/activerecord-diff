module ActiveRecord
  module Diff
    module ClassMethod
      def diff(*attrs)
        self.diff_attrs = attrs
      end
    end

    def self.included(base)
      base.class_attribute :diff_attrs
      base.extend ClassMethod
    end

    def diff?(record = nil)
      not diff(record).empty?
    end

    def diff(other_record = nil)
      if other_record.nil?
        old_record, new_record = self.class.find(id), self
      else
        old_record, new_record = self, other_record
      end

      if new_record.is_a?(Hash)
        diff_each(new_record) do |(attr_name, hash_value)|
          [attr_name, old_record.send(attr_name), hash_value]
        end
      else
        attrs = self.class.diff_attrs

        if attrs.nil?
          attrs = self.class.content_columns.map { |column| column.name.to_sym }
        elsif attrs.length == 1 && Hash === attrs.first
          options = attrs.first
          if options[:include] == :all
            attrs = all_columns - (options[:exclude] || [])
          else
            columns = self.class.content_columns.map { |column| column.name.to_sym }
            attrs = columns + (options[:include] || []) - (options[:exclude] || [])
          end
        end

        diff_each(attrs) do |attr_name|
          [attr_name, old_record.send(attr_name), new_record.send(attr_name)]
        end
      end
    end

    def diff_each(enum)
      enum.inject({}) do |diff_hash, attr_name|
        attr_name, old_value, new_value = *yield(attr_name)

        unless old_value === new_value
          diff_hash[attr_name.to_sym] = [old_value, new_value]
        end

        diff_hash
      end
    end

    def all_columns
      columns = self.class.column_names.map(&:to_sym).reject { |c| self.class.stored_attributes.keys.include?(c) }
      columns |=  self.class.stored_attributes.values.flatten
      columns.uniq
    end
  end
end
