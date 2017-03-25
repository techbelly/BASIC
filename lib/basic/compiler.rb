# frozen_string_literal: true
require 'basic/basiclib'
require 'basic/expression_parser'

module Basic
  module Compiler
    def varname(string)
      "env[\"#{string}\"]"
    end

    include ExpressionParser

    def expression(command, terminators = BasicLib::EXPRESSION_TERMINATORS)
      exp = []
      until command.empty? || should_terminate?(command, terminators)
        exp << command.shift
      end
      return '' if exp.empty?
      "self.evaluate(#{to_reverse_polish(exp).inspect})"
    end

    def should_terminate?(command, terminators)
      terminators.include?(command.first)
    end

    def variable_expression(token, command)
      var = String.new(varname(token))
      if command.first == '('
        var << '[['
        dimensions = []
        begin
          dimensions << expression(index_expression(command))
        end while command.first == '('
        var << dimensions.map { |m| m + '.value' }.join(',')
        var << ']]'
      end
      var
    end

    def index_expression(command)
      out_expression = [command.shift]
      left_brackets = 1
      while left_brackets.positive? && !command.empty?
        token = command.shift
        if left_brackets == 1 && token == ','
          out_expression << ')'
          command.unshift('(')
          break
        end
        out_expression << token
        left_brackets += 1 if token == '('
        left_brackets -= 1 if token == ')'
      end
      out_expression
    end

    def expect(c, *expected)
      value = c.shift
      unless expected.include?(value)
        if value.nil? || value == ''
          puts "Expected #{expected}"
        else
          puts "Expected #{expected}, got #{value}"
        end
        raise SyntaxError, "Expected #{expected}, got #{value}"
      end
      value
    end

    def nextline(num, segment)
      "nextline(#{num},#{segment})"
    end

    def self.simple_statement(name)
      define_method("x_#{name}") do |c, num, seg|
        commands = yield c
        [commands, nextline(num, seg)].join("\n")
      end
    end

    def stringvar?(varn)
      varn =~ /\$$/
    end

    simple_statement(:INPUT) do |c|
      varn = c.shift
      var = varname(varn)
      if stringvar?(varn)
        "#{var} = Value.new(self.readline(\"? \"))"
      else
        "#{var} = Value.new(self.readline(\"? \").to_f)"
      end
    end

    simple_statement(:CLS) do |_c|
      'system("clear")'
    end

    simple_statement(:REM) do |_c|
      ''
    end

    simple_statement(:GOSUB) do |c|
      gnum = expression(c)
      "self.gosub(#{gnum})"
    end

    simple_statement(:DIM) do |c|
      varn = c.shift
      var = varname(varn)
      expect(c, '(')
      sizes = []
      begin
        # TODO: should we allow an expression here?
        sizes << c.shift
        next_token = expect(c, ')', ',')
      end while next_token == ','
      if stringvar?(varn)
        "#{var} = self.create_string_array([#{sizes.join(',')}])"
      else
        "#{var} = self.create_array([#{sizes.join(',')}])"
      end
    end

    simple_statement(:LET) do |c|
      var = variable_expression(c.shift, c)
      expect(c, '=')
      value = expression(c)
      "#{var} = (#{value})"
    end

    def print_tab(c)
      expect(c, 'TAB')
      tabnum = expression(index_expression(c))
      <<-END
        tab = (#{tabnum}).value
        if (tab>0)
          if (tab<self.cols)
            self.print_newline
            self.print " "*(tab % self.maxcol)
          else
            self.print " "*((tab-self.cols) % self.maxcol)
          end
        end
      END
    end

    def print_spc(c)
      expect(c, 'SPC')
      spcnum = expression(index_expression(c))
      <<-END
          self.print " "*((#{spcnum})% self.maxcol)
      END
    end

    simple_statement(:PRINT) do |c|
      statements = []
      statements << "self.print_newline\n" if c.empty?

      terminators = BasicLib::EXPRESSION_TERMINATORS + [',']
      expressions = []
      paren_count = 0
      current_expression = []

      c.each do |token|
        paren_count += 1 if token == '('
        paren_count -= 1 if token == ')'
        if terminators.include?(token) && paren_count == 0
          expressions << [current_expression, token]
          current_expression = []
        else
          current_expression << token
        end
      end

      expressions << [current_expression, nil] unless current_expression.empty?

      expressions.each do |(c, delim)|
        until c.empty?
          if c.first == 'TAB'
            statements << print_tab(c)
          elsif c.first == 'SPC'
            statements << print_spc(c)
          else
            out = expression(c)
            statements << "self.print(#{out})"
          end
        end

        if !delim
          statements << 'self.print_newline'
        else
          delim = expect([delim], ',', ';')
          statements << 'self.print_tab' if delim == ','
        end
      end

      statements.join("\n")
    end

    def x_FOR(c, num, segment)
      varn = c.shift
      var = varname(varn)
      endvar = varname(varn + '_end')
      stepvar = varname(varn + '_step')
      linevar = varname(varn + '_loop_line')
      segvar = varname(varn + '_segment')
      expect(c, '=')
      start = expression(c)
      expect(c, 'TO')
      lend = expression(c)
      step = expression(['1'])
      if c.first == 'STEP'
        c.shift
        step = expression(c)
      end
      <<-END
        step = (#{step})
        raise "STEP ERROR 0" if step == 0
        #{var} = (#{start})
        #{endvar} = (#{lend})
        #{stepvar} = step
        #{linevar},#{segvar} = nextline(#{num},#{segment})
      END
    end

    def x_NEXT(c, num, segment)
      varn = c.shift
      var = varname(varn)
      endvar = varname(varn + '_end')
      stepvar = varname(varn + '_step')
      linevar = varname(varn + '_loop_line')
      segvar = varname(varn + '_segment')
      <<-END
        #{var} = Value.new(#{var}.plus(#{stepvar}))
        value = #{var}.value
        if #{stepvar}.value > 0 && value > #{endvar}.value
          nextline(#{num},#{segment})
        elsif #{stepvar}.value < 0 && value < #{endvar}.value
          nextline(#{num},#{segment})
        else
          [#{linevar},#{segvar}]
        end
      END
    end

    def x_STOP(_c, _num, _segment)
      'raise StopException'
    end

    def x_RUN(_c, _num, _segment)
      'raise RerunException'
    end

    def x_RETURN(_c, _num, _segment)
      'return'
    end

    def x_IF(c, num, segment)
      exp = expression(c)
      expect(c, 'THEN')
      poscommand, negcommand = c.split('ELSE')
      positive = compile(poscommand, num, segment)
      negative = if negcommand
                   compile(negcommand, num, segment)
                 else
                   "nextline(#{num},#{segment})"
                 end
      <<-END
        if (#{exp}.to_b)
          #{positive}
        else
          #{negative}
        end
      END
    end

    def x_GOTO(c, _num, _segment)
      number = c.shift
      "[#{number},0]"
    end

    def compile(c, number, segment)
      command, *rest = c
      send("x_#{command}".to_sym, rest, number, segment)
    end

    extend self
  end
end
