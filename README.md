fluent-plugin-simplearithmetic
================================
This fluentd output plugin helps you to calculate messages.

This plugin is based on [fluent-plugin-datacalculator](https://github.com/muddydixon/fluent-plugin-datacalculator) written by Muddy Dixon.

This plugin doesn't have a summarize function which provided by fluent-plugin-datacalculator.


## Installaion

```
$ fluentd-gem fluent-plugin-simple-arithmetic
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

Now you can calculate this `td-agent.conf`:

```
<match arithmetic.test>
  type simple_arithmetic
  tag calculated.test
  undefined_variables nil
  how_to_process_error error_string

  <formulas>
    total_price   apple * 200 - orange * 100

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

Calculated result is:

```
{
	"apple": 7,
	"orange": 3,
	"time_start": "2001-02-03T04:05:06Z",
	"time_finish": "2001-02-03T04:06:12Z",
	"total_price": 1100,
	"budget": 900,
	"time_elapsed": 66.0
}
```


## Configuration
#### undefined_variables
1. `nil`

2. `undefined`

#### how_to_process_error
1. `nil`


2. `undefined`

3. `error_string`


### tag
The tag prefix for emitted event messages. Default is `simple_arithmetic`.


## Copyright

Copyright:: Copyright (c) 2014- Takahiro Kamatani

License:: Apache License, Version 2.0
