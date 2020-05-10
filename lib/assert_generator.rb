# frozen_string_literal: true

require 'date'
require 'binding_of_caller'

module AssertGenerator
  # Generate asserts based on some actual output from an object under test
  # Outputs executable code to stdout with the assert statements, which can be pasted into the test
  # The user needs to ensure that values are deterministic and do not change between test invocations
  #
  # @overload generate_asserts(source, source_expr)
  #   Generate asserts for a source object supplying an expression to access that object,
  #   e.g: `generate_asserts(res, 'res' )
  #   @param source [Object] an object to generate asserts that the object contains the values as recorded
  #     when this got called
  #   @param source_expr [String] the source expression that created the object, will be repeated into the asserts
  #
  # @overload generate_asserts { block }
  #   Generate asserts for a source object defined in a block - reflect the block to get the source to output
  #     to access the object
  #   @param relative_dates [String] adjust dates to be relative to the supplied date as a string expression
  #     - use with date dependent fixtures
  #   @yield a block which when evaluated returns the source object
  #
  def self.generate_asserts(source = nil, source_expr = nil, relative_dates: nil, numeric_precision: 2, &block)
    AssertGenerator::Klass.new.send(:generate_asserts, source, source_expr, relative_dates, numeric_precision, block)
  end

  class Klass
    attr_accessor :relative_dates, :relative_date_today, :numeric_precision

    def generate_asserts(source, source_expr, relative_dates, numeric_precision, block)
      if block
        unless !defined?(Rails) || Rails.env.test?
          raise 'AssertGenerator must only be used in the test context'
        end

        source_expr = block.call.to_s
        # rubocop:disable Security/Eval
        source ||= eval(source_expr, block.binding)
        # rubocop:enable Security/Eval
      end

      unless source_expr
        raise 'generate_asserts wants a source expression or a block'
      end

      if relative_dates
        self.relative_dates = relative_dates
        # rubocop:disable Security/Eval
        self.relative_date_today = eval(relative_dates, block&.binding ||  binding.of_caller(1))
        # rubocop:enable Security/Eval
      end

      self.numeric_precision = numeric_precision

      if source.is_a?(Hash)
        generate_asserts_hash(source, source_expr)
        return self
      end

      if source.respond_to?(:attributes)
        # AR or something that quacks like it
        generate_asserts_attributes(source, source_expr)
        return self
      end

      if source.is_a?(Range)
        generate_asserts_range(source, source_expr)
        return self
      end

      if source.is_a?(Enumerable)
        generate_asserts_enum(source, source_expr)
        return self
      end

      generate_assert_drillable_item(source, ->(_c) { source_expr }, source)
      self
    end

    # Active Record, or anything else with an attributes hash
    def generate_asserts_attributes(h, p)
      h.attributes.each do |k, v|
        generate_assert_drillable_item(v, ->(meth) { "#{p}.#{meth}" }, k)
      end
    end

    def generate_asserts_hash(h, p)
      h.each do |k, v|
        generate_assert_drillable_item(v, ->(key) do
          key_literal = key.is_a?(Symbol) ? ":#{key}" : "'#{key}'"
          "#{p}[#{key_literal}]"
        end, k)
      end
    end

    def generate_asserts_enum(a, p)
      generate_assert_drillable_item(a.count, ->(_c) { "#{p}.count" }, p)

      a.each_with_index do |v, idx|
        generate_assert_drillable_item(v, ->(index) { "#{p}[#{index}]" }, idx)
      end
    end

    def generate_asserts_range(a, p)
      generate_assert_drillable_item(a.first, ->(_x) { "#{p}.first" }, p)
      generate_assert_drillable_item(a.last, ->(_x) { "#{p}.last" }, p)
    end

    def generate_assert_drillable_item(v, make_accessor, *accessor_params)
      accessor = make_accessor.call(*accessor_params)

      if drillable_object(v)
        return generate_asserts(v, accessor, relative_dates, numeric_precision, nil)
      end

      if v.nil?
        out "assert_nil #{accessor}"
      elsif v.is_a?(true.class)
        out "assert #{accessor}"
      elsif v.is_a?(false.class)
        out "refute #{accessor}"

      elsif v.is_a?(DateTime) || (defined?(ActiveSupport::TimeWithZone) && v.is_a?(ActiveSupport::TimeWithZone))
        generate_date_time_assert(v, accessor)
      elsif v.is_a?(Date)
        generate_date_assert(v, accessor)
      elsif v.is_a?(Float) || v.is_a?(BigDecimal)
        generate_numeric_assert(v, accessor)
      else
        out "assert_equal #{v.inspect}, #{make_accessor.call(*accessor_params)}"
      end
    end

    def out(s)
      puts(s)
    end

    def drillable_object(v)
      v.is_a?(Enumerable) || v.respond_to?(:attributes)
    end

    def generate_date_assert(v, accessor)
      if relative_dates
        date_diff = v - relative_date_today
        if date_diff.to_i == 0
          out "assert_equal #{relative_dates}, #{accessor}"
        else
          out "assert_equal #{relative_dates} #{date_diff.to_i < 0 ? '-' : '+'} #{date_diff.to_i.abs}.days, #{accessor}"
        end
      else
        out "assert_equal Date.new(#{v.year}, #{v.month}, #{v.day}), #{accessor}"
      end
    end

    def generate_date_time_assert(v, accessor)
      out "assert_equal DateTime.new(#{v.year}, #{v.month}, #{v.day}, " \
             + "#{v.hour}, #{v.min}, #{v.sec}, '#{v.zone}'), #{accessor}"
    end

    def generate_numeric_assert(v, accessor)
      if numeric_precision
        assert_code = "assert_equal_d #{v.to_f.round(numeric_precision)}, #{accessor}"
        if numeric_precision != 2
          assert_code += ", #{numeric_precision}"
        end
      else
        assert_code = "assert_equal #{v}, #{accessor}"
      end

      out assert_code
    end
  end
end
