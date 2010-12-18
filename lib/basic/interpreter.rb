require "readline"
require "basic/program"
require "basic/compiler"
require "basic/lexer"

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

class FalseClass
  define_method :"!" do
    true
  end
  
  define_method :"||" do |other| 
    self || other
  end
end

class TrueClass
  define_method :"!" do
    false
  end
end

module Basic
  module Interpreter
    
    def define(number,tokens)
      begin
        commands = tokens.split(':')
        commands.each_with_index do |c,segment|
          method_body = Compiler.compile(c,number,segment)
          Program.define(number,segment,c,method_body)
        end
      rescue SyntaxError => e
        puts "SYNTAX ERROR in LINE #{number}"
        puts e
        puts tokens.join(" ")
      end
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
      when "GENERATED"
        Program.generated
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

    include Lexer
    extend self
  end
end
