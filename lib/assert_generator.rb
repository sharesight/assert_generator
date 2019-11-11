require 'date'

module AssertGenerator

  # Generate asserts based on some actual output from an object under test
  # Outputs executable code to stdout with the assert statements, which can be pasted into the test
  # The user needs to ensure that values are deterministic and do not change between test invocations
  #
  # @overload generate_asserts(source, source_expr)
  #   Generate asserts for a source object supplying an expression to access that object, e.g: `generate_asserts(res, 'res' )
  #   @param source [Object] an object to generate asserts that the object contains the values as recorded when this got called
  #   @param source_expr [String] the source expression that created the object, will be repeated into the asserts
  #
  # @overload generate_asserts { block }
  #   Generate asserts for a source object defined in a block - reflect the block to get the source to output to access the object
  #   @param relative_dates [String] adjust dates to be relative to the supplied date as a string expression - use with date dependent fixtures
  #   @yield a block which when evaluated returns the source object
  #
  def self.generate_asserts(source=nil, source_expr=nil, relative_dates: nil, &block)
    AssertGenerator::Klass.new.send(:generate_asserts, source, source_expr, relative_dates, block)
  end

  class Klass
    attr_accessor :relative_dates, :relative_date_today

    def generate_asserts(source, source_expr, relative_dates, block)
      if block
        raise "AssertGenerator must only be used in the test context" unless !defined?(Rails) || Rails.env.test?

        source_expr = block.call.to_s
        # rubocop:disable Security/Eval
        source ||= eval(source_expr, block.binding)
        # rubocop:enable Security/Eval
      end

      raise "generate_asserts wants a source expression or a block" unless source_expr

      if relative_dates
        raise "relative_dates needs block syntax" unless block

        self.relative_dates = relative_dates
        # rubocop:disable Security/Eval
        self.relative_date_today = eval(relative_dates, block.binding)
        # rubocop:enable Security/Eval
      end

      if source.is_a?(Hash)
        generate_asserts_hash(source, source_expr)
        return self
      end

      if defined?(ActiveRecord::Base) && source.is_a?(ActiveRecord::Base)
        generate_asserts_ar(source, source_expr)
        return self
      end

      if source.is_a?(Enumerable)
        generate_asserts_enum(source, source_expr)
        return self
      end

      generate_assert_drillable_item(source, ->(_c) { source_expr }, source)
      self
    end

    def generate_asserts_ar(h, p)
      h.attributes.each do |k,v|
        generate_assert_drillable_item(v, ->(meth) { "#{p}.#{meth}" }, k)
      end
    end

    def generate_asserts_hash(h, p)
      h.each do |k,v|
        generate_assert_drillable_item(v, ->(sym) { "#{p}[:#{sym}]" }, k)
      end
    end

    def generate_asserts_enum(a, p)
      generate_assert_drillable_item(a.count, ->(_c) { "#{p}.count" }, p)

      a.each_with_index do |v, idx|
        generate_assert_drillable_item(v, ->(index) { "#{p}[#{index}]" }, idx)
      end
    end

    def generate_assert_drillable_item(v, make_accessor, *accessor_params)
      accessor = make_accessor.call(*accessor_params)
      unless drillable_object(v)
        if v.nil?
          out "assert_nil #{accessor}"
        elsif v.is_a?(true.class)
          out "assert #{accessor}"
        elsif v.is_a?(false.class)
          out "refute #{accessor}"

        elsif v.is_a?(DateTime) || (defined?(ActiveSupport::TimeWithZone) && v.is_a?(ActiveSupport::TimeWithZone))
          out "assert_equal DateTime.new(#{v.year}, #{v.month}, #{v.day}, #{v.hour}, #{v.min}, #{v.sec}, '#{v.zone}'), #{accessor}"
        elsif v.is_a?(Date)
          if relative_dates
            date_diff = v - relative_date_today
            if date_diff.to_i == 0
              out "assert_equal #{relative_dates}, #{accessor}"
            else
              out "assert_equal #{relative_dates} + #{date_diff}.days, #{accessor}"
            end
          else
            out "assert_equal Date.new(#{v.year}, #{v.month}, #{v.day}), #{accessor}"
          end

        else
          out "assert_equal #{v.inspect}, #{make_accessor.call(*accessor_params)}"
        end
      else
        generate_asserts(v, accessor, nil, nil)
      end
    end

    def out(s)
      puts(s)
    end

    def drillable_object(v)
      v.is_a?(Enumerable) || (defined?(ActiveRecord::Base) && v.is_a?(ActiveRecord::Base))
    end
  end
end
