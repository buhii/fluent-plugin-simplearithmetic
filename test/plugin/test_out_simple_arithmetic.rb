# -*- coding: utf-8 -*-
require 'helper'

class SimpleArithmeticOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    type simple_arithmetic
    tag calculated.test
    undefined_variables nil
    how_to_process_error error_string

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
    # No formulas
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    # No formulas
    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        <formulas>

        </formulas>
      ]
    }
    # Syntax error
    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        <formulas>
          var1   var2 * var3 +
        </formulas>
      ]
    }
  end

  def test_replace_functions
    d1 = create_driver %[
      replace_hyphen  __H__
      replace_dollar  __D__
      replace_at      __AT__
      <formulas>
        var__H__1        __H__2 * var__D__3
        __D__3           __D__1 + __D__2
        __AT__timestamp  var__AT__
      </formulas>
    ]
    assert_equal '__H__', d1.instance.replace_hyphen
    assert_equal '__D__', d1.instance.replace_dollar
    d1.run do
      time = Time.parse("2011-01-02 13:14:15 UTC").to_i
      d1.emit({'-2'=>10, 'var$3'=>20, 'var@'=>'__at'}, time)
      d1.emit({'$1'=>10, '$2'=>20}, time)
    end
    assert_equal d1.emits[0][2], {"-2"=>10, "var$3"=>20, "var-1"=>200, "var@"=>"__at", "@timestamp"=>"__at"}
    assert_equal d1.emits[1][2], {"$1"=>10, "$2"=>20, "$3"=>30}
  end

  def test_undefined_variables
    # undefined_variables must be either `nil` or `undefined`
    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        undefined_variables   non_existent_config
        <formulas>
          a   b + c
        </formulas>
      ]
    }

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    # nil
    d1 = create_driver %[
      undefined_variables   nil
      <formulas>
        a   b + c
      </formulas>
    ]
    d1.run do
      d1.emit({'b'=>10, 'c'=>20}, time)
      d1.emit({'b'=>10, 'non-related'=>100}, time)
    end
    assert_equal d1.emits[0][2], {'a'=>30, 'b'=>10, 'c'=>20}
    assert_equal d1.emits[1][2], {'a'=>nil, 'b'=>10, 'non-related'=>100}

    # undefined
    d2 = create_driver %[
      undefined_variables   undefined
      <formulas>
        a   b + c
      </formulas>
    ]
    d2.run do
      d2.emit({'b'=>10, 'c'=>20}, time)
      d2.emit({'b'=>10, 'non-related'=>100}, time)
    end
    assert_equal d2.emits[0][2], {'a'=>30, 'b'=>10, 'c'=>20}
    assert_equal d2.emits[1][2], {'b'=>10, 'non-related'=>100}
  end

  def test_how_to_process_error
    # undefined_variables must be either `nil` or `undefined`, `error_string`
    assert_raise(Fluent::ConfigError) {
      d = create_driver %[
        how_to_process_error   non_existent_config
        <formulas>
          a   b + c
        </formulas>
      ]
    }

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    # nil
    d1 = create_driver %[
      how_to_process_error   nil
      <formulas>
        a   b + c
      </formulas>
    ]
    d1.run do
      d1.emit({'b'=>10, 'c'=>20}, time)
      d1.emit({'b'=>10, 'c'=>'string'}, time)
    end
    assert_equal d1.emits[0][2], {'a'=>30, 'b'=>10, 'c'=>20}
    assert_equal d1.emits[1][2], {'a'=>nil, 'b'=>10, 'c'=>'string'}

    # undefined
    d2 = create_driver %[
      how_to_process_error   undefined
      <formulas>
        a   b + c
      </formulas>
    ]
    d2.run do
      d2.emit({'b'=>10, 'c'=>20}, time)
      d2.emit({'b'=>10, 'c'=>'string'}, time)
    end
    assert_equal d2.emits[0][2], {'a'=>30, 'b'=>10, 'c'=>20}
    assert_equal d2.emits[1][2], {'b'=>10, 'c'=>'string'}

    # error_string
    d3 = create_driver %[
      how_to_process_error   error_string
      <formulas>
        a   b + c
      </formulas>
    ]
    d3.run do
      d3.emit({'b'=>10, 'c'=>20}, time)
      d3.emit({'b'=>10, 'c'=>'string'}, time)
    end
    assert_equal d3.emits[0][2], {'a'=>30, 'b'=>10, 'c'=>20}
    assert_equal d3.emits[1][2], {'a'=>"String can't be coerced into Fixnum",
                                  'b'=>10, 'c'=>'string'}
  end

  def test_plus_num_and_string
    def calculated(record)
      record['a'] = record['b'] + record['c']
      record
    end
    data = [
      {'b'=>10, 'c'=>20},
      {'b'=>'Dr. Strangelove or: ',
       'c'=>'How I Learned to Stop Worrying and Love the Bomb'},
    ]

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d = create_driver %[
      <formulas>
        a   b + c
      </formulas>
    ]
    d.run do
      data.each {|record|
        d.emit(record, time)
      }
    end
    data.each_with_index {|record, index|
      assert_equal d.emits[index][2], calculated(data[index])
    }
  end

  def test_iso8601
    d = create_driver %[
      <formulas>
        time_diff   Time.iso8601(time_finish) - Time.iso8601(time_start)
      </formulas>
    ]
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.run do
      d.emit(
        {
          'time_start'  => '2001-02-03T04:05:06Z',
          'time_finish' => '2001-02-03T04:06:12Z',
        }, time)
    end
    assert_equal d.emits[0][2], {
      'time_start' =>  '2001-02-03T04:05:06Z',
      'time_finish'=> '2001-02-03T04:06:12Z',
      'time_diff'=> 66.0}
  end

end
