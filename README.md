fluent-plugin-simplearithmetic
================================
This fluentd output plugin helps you to calculate messages.

This plugin is based on [fluent-plugin-datacalculator](https://github.com/muddydixon/fluent-plugin-datacalculator) written by Muddy Dixon. This plugin doesn't have a summarize function which provided by fluent-plugin-datacalculator.


## Installaion

```
$ fluent-gem install fluent-plugin-simplearithmetic
```

## Tutorial

Suppose you have a message like:

```
{
  'apple': 7,
  'orange': 3,
  'time_start': '2001-02-03T04:05:06Z',
  'time_finish': '2001-02-03T04:06:12Z',
}
```

Now you can calculate with this configuration:

```
<match arithmetic.test>
  type simple_arithmetic
  tag calculated.test

  <formulas>
    total_price   apple * 200 + orange * 100

    # Calculation order is from up to down.
    budget   2000 - total_price

    # You can also use Time.iso8601
    time_elapsed   Time.iso8601(time_finish) - Time.iso8601(time_start)
  </formulas>
</match>

<match calculated.test>
  type stdout
</match>
```

Calculated results will be:

```
{
	"apple": 7,
	"orange": 3,
	"time_start": "2001-02-03T04:05:06Z",
	"time_finish": "2001-02-03T04:06:12Z",
	"total_price": 1700,
	"budget": 300,
	"time_elapsed": 66.0
}
```

If some fields are already defined before calculation, these fields will be overwritten.


## Configuration

### tag
The tag prefix for emitted event messages. Default is `simple_arithmetic`.

### undefined_variables

A message such like `{'a':  20, 'x':  50}` with the formulas:

```
<formulas>
  c   a + b
</formulas>
```

When undefined_variables is `undefined` (default) you get `{'a':  20, 'x':  50}`. Field `'c'` will not be defined.

When `nil` you get `{'a':  20, 'c': nil, 'x':  50}`.


### how_to_process_error

A message such like `{'a':  20, 'b':  "string"}` with the formulas:

```
<formulas>
  c   a + b
</formulas>
```

In ruby, this calculation will be raise an error:

```
irb(main):052:0* a = 20
=> 20
irb(main):053:0> b = "String"
=> "String"
irb(main):054:0> c = a + b
TypeError: String can't be coerced into Fixnum
	from (irb):54:in `+'
	from (irb):54
	from /opt/td-agent/embedded/bin/irb:11:in `<main>'
```

When how_to_process_error is `nil` you get `{'a':  20, 'b': "string", 'c': nil}`.

When `undefined`, you get `{'a':  20, 'b': "string"}`. If an error is raised in the calculation, the field will not be defined.

When `error_string` (default), you get: `{'a':  20, 'b': "String", 'c'=>"String can't be coerced into Fixnum"}`. An error message will be assigned to the field.

### replace_hyphen, replace_dollar

All formulas will be evaluated as ruby sentences. Some json fields will not be fitted as ruby variables. For example, 

```
<formulas>
   var-1   a + b
   var$2   c * d
</formulas>
```

will raise an syntax error in the initialize process of fluentd.

To get rid of this case, you can set `replace_hyphen` and `replace_dollar` in the configuration and formulas.

```
replace_hyphen   __H__
replace_dollar   __D__

<formulas>
   var__H__1   a + b
   var__D__2   c * d
</formulas>
```


## Copyright

Copyright:: Copyright (c) 2014- Takahiro Kamatani

License:: Apache License, Version 2.0
