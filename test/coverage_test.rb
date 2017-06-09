require 'test/unit/collector/descendant'
require 'test/unit/testresult.rb'
require 'pry'
require 'coverage'
Coverage.start

require './test/basic_test'

Test::Unit::AutoRunner.need_auto_run=false

#collector = Test::Unit::Collector::Load.new
#puts collector.collect()

collector = Test::Unit::Collector::Descendant.new
suite = collector.collect($0.sub(/\.rb\Z/, ''))

tests_to_do = suite.tests[0].tests
tests_done = []

puts tests_to_do

#until tests_to_do.empty? do
  #tests_to_do.each do |test|
    test = tests_to_do.first
    suite = Test::Unit::TestSuite.new
    tests_done.each do |done_test|
      suite << done_test
    end
    suite << test
    suite.run(Test::Unit::TestResult.new) { |a| puts a}
  #end
#end

coverage = Coverage.result

require 'parser/current'
require 'unparser'

paths = coverage.keys.select { |path| path =~ /BASIC/ }

ruby_file = File.read(paths[1])
puts paths[1]
parse_tree = Parser::CurrentRuby.parse(ruby_file)
puts parse_tree.children[4].location.line, parse_tree.children[4].location.last_line
puts Unparser.unparse(parse_tree.children[4])
