module Fluent

  class SimpleArithmeticOutput < Output
    Fluent::Plugin.register_output('simple_arithmetic', self)

    config_param :tag, :string, :default => "calculated"

    # 'nil', 'undefined'
    config_param :undefined_variables, :string, :default => 'undefined'

    # 'nil', 'undefined', 'error_string'
    config_param :how_to_process_error, :string, :default => 'error_string'

    attr_accessor :_formulas

    def initialize
      super
      require 'time'
    end

    def start
      super
    end

    def shutdown
      super
    end

    def configure(conf)
      super

      # Check configuration
      {'undefined_variables'  => %w{nil undefined},
       'how_to_process_error' => %w{nil undefined error_string}}.each_pair{|attr, choices|
        param = instance_variable_get('@' + attr)
        if not choices.include? param
          raise Fluent::ConfigError, \
                "Invalid setting at #{attr}: `#{param}`. Choices: %s" % choices.join(', ')
        end
      }

      # Create functions
      @_formulas = []

      def create_func(var, expr)
        begin
          f_argv = expr.scan(/[a-zA-Z][\w\d\.]*/).uniq.select{|x| not x.start_with?('Time.iso8601')}
          f = eval('lambda {|' + f_argv.join(',') + '| ' + expr + '}')
          return [f, f_argv]
        rescue SyntaxError
          raise Fluent::ConfigError, "SyntaxError at formula `#{var}`: #{expr}"
        end
      end

      conf.elements.select { |element|
        element.name == 'formulas'
      }.each { |element|
        element.each_pair { |var, expr|
          element.has_key?(var)   # to suppress unread configuration warning
          formula, f_argv = create_func(var, expr)
          @_formulas.push [var, f_argv, formula]
        }
      }
    end

    def has_all_keys?(record, argv)
      argv.each {|var|
        if not record.has_key?(var)
          return false
        end
      }
      true
    end

    def exec_func(record, f_argv, formula)
      argv = []
      f_argv.each {|v|
        argv.push(record[v])
      }
      return formula.call(*argv)
    end

    def calculate(record)
      @_formulas.each {|var, f_argv, formula|
        if not has_all_keys?(record, f_argv)
          if @undefined_variables == 'nil'
            record[var] = nil
          end
          next
        end

        begin
          record[var] = exec_func(record, f_argv, formula)
        rescue StandardError => error
          case @how_to_process_error
          when 'error_string'
            record[var] = error.to_s
          when 'nil'
            record[var] = nil
          end
        end
      }
      record
    end

    def emit(tag, es, chain)
      chain.next
      es.each { |time, record|
        Fluent::Engine.emit(@tag, time, calculate(record))
      }
    end
  end
end
