# frozen_string_literal: true
require 'basic/basiclib'
require 'basic/runtime'

module Basic
  class StopException < RuntimeError
  end

  class RerunException < RuntimeError
  end

  class Program
    def self.run
      begin
        rerun = false
        @env = {}
        line_no = @lines.keys.min
        return unless line_no
        begin
          b = new
          b.gosub(line_no)
        rescue StopException
        rescue RerunException
          rerun = true
        end
      end while rerun
    end

    class << self
      attr_reader :env
    end

    def self.list
      @lines.sort_by { |num, _| num }.each do |num, parts|
        print num
        parts.each do |statements|
          spaced = statements.map do |s|
            s =~ /^[A-Z]{2,}$/ && !FUNCTIONS.include?(s)
          end
          (0...statements.length).each do |i|
            print ' ' if i.zero? || spaced[i] || spaced[i - 1]
            print statements[i]
          end
        end
        puts
      end
    end

    def self.generated
      @generated.keys.sort.each do |k|
        puts @generated[k]
      end
    end

    def self.next(num, segment)
      if @lines[num][segment + 1]
        [num, segment + 1]
      elsif next_line = @lines.keys.select { |m| m > num }.min
        [next_line, 0]
      end
    end

    def self.clear
      @lines = {}
      @generated = {}
    end

    def self.renumber(increment = 10)
      old_numbers = @lines.keys.sort
      new_numbers = (1..@lines.length).map { |v| v * increment.to_i }
      retarget = Hash[*old_numbers.zip(new_numbers).flatten]
      @lines = @lines.inject({}) do |new_lines, (num, parts)|
        new_num = retarget[num]
        (1...parts.length).each do |i|
          if %w(GOTO GOSUB).include?(parts[i - 1])
            parts[i] = retarget[parts[i].to_i].to_s
          end
        end
        new_lines.merge(new_num => parts)
      end
    end

    def self.method_name(num, seg = 0)
      "line_#{num}_#{seg}".to_sym
    end

    def self.remove(num)
      @lines[num].each_with_index do |seg, i|
        remove_method(method_name(num, i))
        @generated.delete([num, seg])
      end
      @lines.delete(num)
    end

    def self.define(num, seg, t, s)
      name = method_name(num, seg)
      method = ["def #{name}", s, 'end'].join("\n")
      eval(method)
      @generated[[num, seg]] = method
      @lines[num] = [] unless @lines[num]
      @lines[num][seg] = t
    end

    include BasicLib
    include Runtime
  end
end
