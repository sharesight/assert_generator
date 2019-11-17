# frozen_string_literal: true

require 'test_helper'

require 'assert_generator'

class Trivial < MiniTest::Test
  context 'Make a result' do
    setup do
      n = 2 + 3
      @res = {
        number: n,
        text: "(2 + 3) = #{n}"
      }
    end

    should 'produce some code on stdout' do
      AssertGenerator.generate_asserts(@res, '@res')
    end

    should 'produce some code as expected' do
      AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal 5, @res[:number]').once
      AssertGenerator::Klass.any_instance.expects(:out).with('assert_equal "(2 + 3) = 5", @res[:text]').once

      AssertGenerator.generate_asserts(@res, '@res')
    end

    should 'use generated code' do
      assert_equal 5, @res[:number]
      assert_equal '(2 + 3) = 5', @res[:text]
    end
  end
end
