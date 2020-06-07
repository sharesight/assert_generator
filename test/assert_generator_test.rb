# frozen_string_literal: true

require 'test_helper'
require 'date'

module ActiveRecord
  class Base; end
end

class TestWithAttributes
  def a
    'a'
  end

  def b
    'b'
  end

  def attributes
    { a: a, b: b }
  end
end

class AssertGeneratorTest < Minitest::Test
  context 'gem' do
    should 'have a version number' do
      refute_nil ::AssertGenerator::VERSION
    end

    setup do
      @hash = { a: 100, s: 'Hello' }
    end

    context 'with an object and expression string' do
      should 'generate assert code' do
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 100, @hash[:a]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal "Hello", @hash[:s]').once

        AssertGenerator.generate_asserts(@hash, '@hash')
      end
    end

    context 'with a block returning an expression' do
      # Experimental
      should 'generate assert code' do
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 100, @hash[:a]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal "Hello", @hash[:s]').once

        AssertGenerator.generate_asserts { '@hash' }
      end

      should 'adjust dates when relative_dates given' do
        date = Date.today + 15
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal Date.today + 15.days, date').once

        AssertGenerator.generate_asserts(relative_dates: 'Date.today') { 'date' }
      end

      should 'adjust dates when relative_dates given and on that date' do
        date = Date.today
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal Date.today, date').once

        AssertGenerator.generate_asserts(relative_dates: 'Date.today') { 'date' }
      end
    end

    context 'with an array' do
      should 'assert count and members' do
        array = [1, 2, 3]
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 3, array.count').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 1, array[0]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 2, array[1]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 3, array[2]').once

        AssertGenerator.generate_asserts(array, 'array')
      end
    end

    context 'with a range' do
      should 'assert first and last' do
        range = (1..4)
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 1, range.first').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 4, range.last').once

        AssertGenerator.generate_asserts { 'range' }
      end
    end

    context 'with a hash' do
      should 'generate correct asserts with string keys' do
        hash = { 'a' => 1, 'z' => { 'q' => 100, 'p' => 200 } }
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 1, hash['a']").once
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 100, hash['z']['q']").once
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 200, hash['z']['p']").once

        AssertGenerator.generate_asserts(hash, 'hash')
      end

      should 'generate correct asserts with symbolic keys' do
        hash = { a: 1, z: { q: 100, p: 200 } }
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 1, hash[:a]").once
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 100, hash[:z][:q]").once
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 200, hash[:z][:p]").once

        AssertGenerator.generate_asserts(hash, 'hash')
      end

      should 'generate correct asserts with mixed keys' do
        hash = { a: 1, z: { q: 100, 'p' => 200 } }
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 1, hash[:a]").once
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 100, hash[:z][:q]").once
        AssertGenerator::Klass.any_instance.expects(:out).with("assert_equal 200, hash[:z]['p']").once

        AssertGenerator.generate_asserts(hash, 'hash')
      end
    end

    context 'with nested array and hashes' do
      should 'assert count and members' do
        mixed = { a: [1, 2, { x: 100, y: 200 }], f: 1.234, r: (5..7) }

        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 3, mixed[:a].count').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 1, mixed[:a][0]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 2, mixed[:a][1]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 100, mixed[:a][2][:x]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 200, mixed[:a][2][:y]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_in_delta 1.23, mixed[:f], 0.01').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 5, mixed[:r].first').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 7, mixed[:r].last').once

        AssertGenerator.generate_asserts(mixed, 'mixed')
      end

      should 'adjust dates when relative_dates given' do
        nested = { a: [Date.today - 10, Date.today] }
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 2, nested[:a].count').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal Date.today - 10.days, nested[:a][0]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal Date.today, nested[:a][1]').once

        AssertGenerator.generate_asserts(relative_dates: 'Date.today') { 'nested' }
      end

    end

    context 'with an enumerable' do
      should 'assert count and members' do
        set = Set.new(%w(a b))
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 2, set.count').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal "a", set[0]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal "b", set[1]').once

        AssertGenerator.generate_asserts(set, 'set')
      end
    end

    context 'with a (fake) ActiveRecord' do
      should 'assert attributes' do
        ar = ActiveRecord::Base.new
        ar.stubs(:attributes).returns(a: 100, b: 200)
        ar.expects(:z).never

        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 100, ar.a').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 200, ar.b').once

        AssertGenerator.generate_asserts(ar, 'ar')
      end
    end

    context 'with a class that provides attributes' do
      should 'assert attributes' do
        c = TestWithAttributes.new

        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal "a", c.a').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal "b", c.b').once

        AssertGenerator.generate_asserts(c, 'c')
      end
    end

    context 'with value types' do
      should 'generate appropriate asserts' do
        hash_all = {
          n: nil,
          t: true,
          f: false,
          d: Date.new(2019, 1, 1),
          dt: DateTime.new(2018, 3, 1, 17, 0, 0),
          fl: 3.142
        }

        AssertGenerator::Klass.any_instance.expects(:out).with('assert_nil hash_all[:n]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert hash_all[:t]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('refute hash_all[:f]').once
        AssertGenerator::Klass.any_instance.expects(:out) \
          .with('assert_equal Date.new(2019, 1, 1), hash_all[:d]').once
        AssertGenerator::Klass.any_instance.expects(:out) \
          .with("assert_equal DateTime.new(2018, 3, 1, 17, 0, 0, '+00:00'), hash_all[:dt]").once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_in_delta 3.14, hash_all[:fl], 0.01').once

        AssertGenerator.generate_asserts(hash_all, 'hash_all')
      end
    end

    context 'with floats' do
      should 'assert with configured precision' do
        hash = {
            fl: 3.14159,
            dec: BigDecimal('9.8765')
        }

        AssertGenerator::Klass.any_instance.expects(:out).with('assert_in_delta 3.14, hash[:fl], 0.01').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_in_delta 9.88, hash[:dec], 0.01').once
        AssertGenerator.generate_asserts(hash, 'hash')

        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 3.14159, hash[:fl]').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 0.98765e1, hash[:dec]').once
        AssertGenerator.generate_asserts(numeric_precision: nil) { 'hash' }

        AssertGenerator::Klass.any_instance.expects(:out).with('assert_in_delta 3.142, hash[:fl], 0.001').once
        AssertGenerator::Klass.any_instance.expects(:out).with('assert_in_delta 9.877, hash[:dec], 0.001').once
        AssertGenerator.generate_asserts(numeric_precision: 3) { 'hash' }
      end
    end
  end
end
