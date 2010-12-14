require "basic/basiclib"

module Basic
  module Compiler
    extend self

    def varname(string)
      "env[\"#{string}\"]"
    end

    def funcname(string)
      string.downcase.gsub("$","_string")
    end

    def expression(command)
      expression = []
      while token = translate_token(command,expression)
        expression << token
      end
      expression.join("")
    end

    def basic_operator_to_ruby(op)
      case op
      when "="
        "=="
      when "<>"
        "!="
      when "AND"
        "&&"
      when "OR"
        "||"
      else
        op.downcase
      end
    end

    def translate_token(command,expression)
      return nil if command.empty?
      token = command.shift

      if BasicLib::OPERATORS.include?(token)
       basic_operator_to_ruby(token)
      elsif BasicLib::EXPRESSION_TERMINATORS.include?(token)
       command.unshift(token)
       nil
      elsif token =~ /^\d+(\.\d+)?$/
       token
      elsif token[0..0] == "\""
       token
      elsif BasicLib::FUNCTIONS.include?(token)
       "self.#{funcname(token)}"
      else
       variable_expression(token,command)
      end
    end
    
    def variable_expression(token,command)
      var = varname(token)
       if command.first == "("
        var << "[["
        dimensions = []
        begin
          dimensions << expression(index_expression(command))
        end while command.first == "("
        var << dimensions.join(",")
        var << "]]"
       end
       var
    end
    
    def index_expression(command)
      out_expression = [command.shift]
      left_brackets = 1
      while left_brackets > 0 && !command.empty?
        token = command.shift
        if left_brackets == 1 && token == ","
          out_expression << ")"
          command.unshift("(")
          break
        end
        out_expression << token
        left_brackets += 1 if token == "("
        left_brackets -= 1 if token == ")"
      end
      out_expression
    end

    def expect(c,*expected)
      value = c.shift
      unless expected.include?(value)
        if value.nil? || value == ""
          puts "Expected #{expected}"
        else
          puts "Expected #{expected}, got #{value}"
        end
        raise SyntaxError.new("Expected #{expected}, got #{value}")
      end
      value
    end

    def nextline(num,segment)
      "nextline(#{num},#{segment})"
    end

    def self.simple_statement(name,&body)
      define_method("x_#{name}") do |c,num,seg|
        commands = yield c
        [commands,nextline(num,seg)].join("\n")
      end
    end
    
    def stringvar?(varn)
      varn =~ /\$$/
    end
    
    simple_statement(:INPUT) do |c|
      varn = c.shift
      var = varname(varn)
      if stringvar?(varn)
          "#{var} = self.readline(\"? \")"
      else
          "#{var} = self.readline(\"? \").to_f"
      end
    end

    simple_statement(:CLS) do |c|
      'system("clear")'
    end

    simple_statement(:REM) do |c|
      ''
    end

    simple_statement(:GOSUB) do |c|
      gnum = expression(c)
      "self.gosub(#{gnum})"
    end

    simple_statement(:DIM) do |c|
      varn = c.shift
      var = varname(varn) 
      expect(c,"(") 
      sizes = []
      begin
        # TODO: should we allow an expression here?
        sizes << c.shift
        next_token = expect(c,")",",")
      end while next_token == ","
      if stringvar?(varn)
        "#{var} = self.create_string_array([#{sizes.join(",")}])"
      else
        "#{var} = self.create_array([#{sizes.join(",")}])"
      end
    end
    
    simple_statement(:LET) do |c|
      var = variable_expression(c.shift,c)
      expect(c,"=")
      value = expression(c)
      "#{var} = (#{value})"
    end

    def print_tab(c)
      expect(c,"TAB")
      tabnum = expression(index_expression(c))
      output = <<-END
        tab = (#{tabnum})
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
      expect(c,"SPC")
      spcnum = expression(index_expression(c))
      output = <<-END
          self.print " "*((#{spcnum})% self.maxcol)
      END
    end

    simple_statement(:PRINT) do |c|
      statements = []
      statements << "self.print_newline" if c.empty?   
      while not c.empty? && ! BasicLib::EXPRESSION_TERMINATORS.include?(c.first)
        if c.first == "TAB"
          statements << print_tab(c)
        elsif c.first == "SPC"
          statements << print_spc(c)
        else
          out = expression(c)
          statements << "self.print(#{out})"
        end
        if c.empty?
          statements << "self.print_newline"
        else
          delim = expect(c,",",";")
          if delim == ","
            statements << "self.print_tab"
          elsif delim == ";"
            break if c.empty?
          end
        end
      end
      statements.join("\n")
    end

    def x_FOR(c,num,segment)
      varn = c.shift
      var = varname(varn)
      endvar = varname(varn+"_end")
      stepvar = varname(varn+"_step")
      linevar = varname(varn+"_loop_line")
      segvar = varname(varn+"_segment")
      expect(c,"=")
      start = expression(c)
      expect(c,"TO")
      lend = expression(c)
      step = 1
      if c.first == "STEP"
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

    def x_NEXT(c,num,segment)
      varn = c.shift
      var = varname(varn)
      endvar = varname(varn+"_end")
      stepvar = varname(varn+"_step")
      linevar = varname(varn+"_loop_line")
      segvar = varname(varn+"_segment")
      <<-END
        #{var} += #{stepvar}
        if #{stepvar} > 0 && #{var} > #{endvar}
          nextline(#{num},#{segment})
        elsif #{stepvar} < 0 && #{var} < #{endvar}
          nextline(#{num},#{segment})
        else
          [#{linevar},#{segvar}]
        end
      END
    end

    def x_STOP(c,num,segment)
      "raise StopException"
    end
    
    def x_RUN(c,num,segment)
       "raise RerunException"
    end
    
    def x_RETURN(c,num,segment)
      "return"
    end

    def x_IF(c,num,segment)
      exp = expression(c)
      expect(c,"THEN") 
      poscommand,negcommand = c.split("ELSE")
      positive = self.compile(poscommand,num,segment)
      if negcommand
        negative = self.compile(negcommand,num,segment)
      else
        negative = "nextline(#{num},#{segment})"
      end
      <<-END
        if (#{exp}) 
          #{positive}
        else
          #{negative}
        end
      END
    end

    def x_GOTO(c,num,segment)
      number = c.shift
      "[#{number},0]"
    end

    def compile(c,number,segment)
      command,*rest = c
      self.send("x_#{command}".to_sym,rest,number,segment)
    end
  end
end
