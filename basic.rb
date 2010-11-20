#!/usr/bin/env ruby

require 'readline'


class StopException < Exception
end

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

module BasicLib
  def rnd(num)
    rand*num.to_f
  end
  
  def chr_string(int)
    int.chr
  end
  
  def int(num)
    num.to_i
  end
  
end

module Runtime
  def gosub(line_no)
    while line_no 
      method_name = self.class.method_name(line_no)
      line_no = self.send(method_name)
    end
  end
  
  def readline(prompt)
    return Readline.readline(prompt)
  end
  
  def nextline(num)
    nextline = self.class.next(num)
  end
end

class Program
  
  def self.run()
    line_no = @lines.keys.min
    return unless line_no
    begin
      b = self.new
      b.gosub(line_no) 
    rescue StopException
    end
  end
  
  def self.list()
    puts @lines.inspect
  end
  
  def self.next(num)
     @lines.keys.select {|m| m > num }.min
  end
  
  def self.clear()
    @lines = {}
  end
  
  def self.method_name(num)
    method_name = "line_#{num}".to_sym
  end
  
  def self.remove(num)
    @lines.delete(num)
    remove_method(method_name(num))
  end
  
  def self.define(num,t,s)
    name = method_name(num)
    method = "def #{name}\n#{s}\nend\n"
    begin
      eval(method)
      @lines[num] = t
    rescue SyntaxError
      puts "SYNTAX ERROR in LINE #{num}"
      puts t.join(" ")
    end
  end
  
  include BasicLib
  include Runtime
  
end

module Compiler
  extend self
  
  def varname(string)
    string.downcase.gsub("$","_string")
  end
  
  def expression(command)
    expression = []
    command = command.dup
    while token = translate_token(command,expression)
      expression << token
    end
    [command,expression.join("")]
  end

  def translate_token(command,expression)
    return nil if command.empty?
    token = command.shift
    operators = "+-*/=<>()"
    expression_terminators = [",",":",";","THEN","TO"]
    
    # TODO: SHOULD GENERATE THIS FROM BasicLib
    functions = ["RND","INT","CHR$","INKEY$","ABS","VAL","ASC","SGN","SQR","SIN","ATN"]

    if operators.include?(token)
     token == "=" ? "==" : token
    elsif expression_terminators.include?(token)
     command.unshift(token)
     nil
    elsif token =~ /\d+/
     token
    elsif token[0..0] == "\""
     token
    elsif functions.include?(token)
     "self.#{varname(token)}"
    else
     "@"+varname(token)
    end
  end
  
  def nextline(num)
    "return nextline(#{num})"
  end
  
  def x_STOP(c,num)
    ["raise StopException"]
  end
  
  def x_RETURN(c,num)
    ["return"]
  end
  
  def x_GOSUB(c,num)
    # GOSUB 200
    gnum = c.shift
    ["self.gosub(#{gnum})",nextline(num)]
  end
  
  def x_IF(c,num)
    c,exp = expression(c)
    c.shift # THEN
    [ "if (#{exp}) then",
        self.compile(c,num),
      "else",
        "return nextline(#{num})",
      "end"]
  end
  
  def x_INPUT(c,num)
    var = varname(c.shift)
    statements <<-END
      @#{var} = self.readline("? ")
      return nextline(#{num})
    END
  end
  
  def statements(text)
    text.split(/\n/).map{ |line| line.strip }
  end
  
  def x_LET(c,num)
    var = varname(c.shift)
    c.shift # =
    c,value = expression(c)
    statements <<-END
      @#{var} = (#{value})
      return nextline(#{num})
    END
  end
  
  def x_FOR(c,num)
    # FOR I = 1 TO 10
    var = varname(c.shift)
    c.shift # = 
    c,start = expression(c)
    c.shift # TO
    c,lend = expression(c)
    statements <<-END
      @#{var} = (#{start})
      @#{var}_end = (#{lend})
      @#{var}_loop_line_no = nextline(#{num})
      return nextline(#{num})
    END
  end
  
  def x_NEXT(c,num)
    # NEXT I
    var = varname(c.shift)
    statements <<-END
        @#{var} += 1
        if @#{var} > @#{var}_end
          return nextline(#{num})
        else
          return @#{var}_loop_line_no
        end
    END
  end
  
  def x_PRINT(c,num)
    # PRINT "Hello"
    statements = []
    while not c.empty?
      c,out = expression(c)
      statements << "print (#{out})"
      if c.empty?
        statements << "print \"\\n\""
      else
        delim = c.shift
        if delim == ","
          statements << "print \"\\t\""
        elsif delim == ";"
          break if c.empty?
        end
      end
    end
    statements << "return nextline(#{num})"
    statements
  end
  
  def x_GOTO(c,num)
    # GOTO 20
    number = c.shift
    ["return #{number}"]
  end
  
  def compile(c,number)
    command,*rest = c
    self.send("x_#{command}".to_sym,rest,number).join("\n")
  end
  
end

def define(number,tokens)
  commands = tokens.split(':')
  statements = []
  commands.each do |c|
    statements << Compiler.compile(c,number)
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
  else
    puts "HUH?"
  end
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
    
  elsif "+-*/=<>().:;,".include?(first)
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

def reader(cmd=nil)
  cmd ||= lambda { Readline.readline('> ',true) }
  while line = cmd.call()
    first,*rest = read(line)
    if first =~ /\d+/
      compile first.to_i, rest
    else
      execute first,rest
    end
  end
end

Program.clear
print "\nREADY\n"
reader