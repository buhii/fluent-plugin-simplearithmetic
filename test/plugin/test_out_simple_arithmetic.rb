# -*- coding: utf-8 -*-
require 'helper'

class SimpleArithmeticOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    type simple_arithmetic
    tag calculated.test
    undefined_variables nil   # nil, undefined
    how_to_process_error error_string   # nil, undefined, error_string

    <formulas>
      x3     x1 * 100 - x2
      var1   Time.iso8601(t1) - Time.iso8601(t2)
      var2   x3 - var1
    </formulas>
  ]

  def create_driver(conf = CONFIG, tag='test.input')
    Fluent::Test::OutputTestDriver.new(Fluent::SimpleArithmeticOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    # no variables for calculation
    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        <formulas>

        </formulas>
      ]
    }
    # Syntax Error
    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        <formulas>
          var_undefined
        </formulas>
      ]
    }
    d = create_driver %[
        <formulas>
          var1   var2 * var3
        </formulas>
    ]
  end

  def test_create_formula
    d = create_driver
  end

  def test_write
    d = create_driver
  end
end
