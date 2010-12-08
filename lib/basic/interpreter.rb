require "readline"
require "basic/program"
require "basic/compiler"

class Array
  def split(delim)
    self.inject([[]]) do |c, e|
       if e == delim
         c << []
       else
         c.last << e
       end
       c
    end
  end
end

class String
  def strip_str(str)
    gsub(/^#{str}|#{str}$/, '')
  end
end

class Fixnum
  def /(other)
    self.to_f / other
  end
end

module Basic
  module Interpreter
    def define(number,tokens)
      commands = tokens.split(':')
      statements = []
      commands.each do |c|
        statements << Compiler.compile(c,number)
      end
      if $DEBUG
        puts statements.join("\n")
      end
      Program.define(number,tokens,statements.join("\n"))
    end

    def compile(number,tokens)
      if tokens.empty?
        Program.remove(number)
      else
        define number,tokens
      end
    end

    def execute(line,rest)
      case line
      when "RUN"
        Program.run
      when "LIST"
        Program.list
      when "RENUMBER"
        Program.renumber *rest
      when "LOAD"
        Program.clear
        filename = rest.shift.strip_str("\"")
        f = File.open(filename)
        reader(lambda do
          line = f.gets
          if line
            return line.chomp
          else
            return false
          end
        end)
      when "EXIT"
        return false
      else
        puts "HUH?"
      end
      return true
    end

    def read(input,output=[],token='')
      if input.empty?
        output.push(token) unless token.empty?
        return output
      end

      first,rest = input[0..0],input[1..-1]

      if first == " "
        output.push(token) unless token.empty?
        read(rest, output)

      elsif first == "\""
        output.push(token) unless token.empty?
        read_string(rest, output)
      
      elsif "<".include?(first)
        output.push(token) unless token.empty?
        next_token = rest[0..0]
        case next_token
          when ">"
            read(rest[1..-1], output+["<>"],"")
          when "="
            read(rest[1..-1], output+["<="],"")
          else
            read(rest,output+["<"],"")
        end
      
      elsif ">".include?(first)
        output.push(token) unless token.empty?
        next_token = rest[0..0]
        case next_token
          when "="
            read(rest[1..-1], output+[">="],"")
          else
            read(rest,output+[">"],"")
        end
         
      elsif "+-*/=():;,".include?(first)
        output.push(token) unless token.empty?
        read(rest, output + [first], "")

      else
        read(rest,output,token+first)
      end

    end

    def read_string(input,output,string='')
      if input.empty?
        raise "[String needs end quote]"
      end

      first,rest = input[0..0],input[1..-1]
      if first == "\""
        return read(rest,output+["\"#{string}\""],"")
      else
        return read_string(rest,output,string+first)
      end
    end

    def reader(cmd)
      while line = cmd.call()
        first,*rest = read(line)
        if first =~ /\d+/
          compile first.to_i, rest
        else
          execute first,rest or return
        end
      end
    end

    def run(cmd=nil)
      cmd ||= lambda { Readline.readline('> ',true) }
      Program.clear
      print "\nREADY\n"
      reader cmd
    end

    extend self
  end
end
