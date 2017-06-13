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

#puts tests_to_do

#until tests_to_do.empty? do
  #tests_to_do.each do |test|
    test = tests_to_do.first
    suite = Test::Unit::TestSuite.new
    tests_done.each do |done_test|
      suite << done_test
    end
    suite << test
    suite.run(Test::Unit::TestResult.new) { |a| }
  #end
#end

coverage = Coverage.result

require 'parser/current'
require 'unparser'

paths = coverage.keys.select { |path| path =~ /BASIC/ }

class CoverageCleaner < Struct.new(:coverage)

  def process(node)

    return node unless node.is_a? Parser::AST::Node
    return node unless node.location.expression

    first_line, last_line = node.location.first_line-1, node.location.last_line-1
    if coverage[first_line..last_line].compact.empty? or coverage[first_line..last_line].compact.inject(0, :+) == 0
      :empty
    else
      node.updated(node.type, cleaned(node), {location: node.location})
    end
  end

  def cleaned(nodes)
    nodes.to_a.map { |node| process(node) }.delete_if {|e| e == :empty }
  end
end

paths.each do | path |
#path = paths[2]
  ruby_source = File.read(path)
  coverage_result = coverage[path]
  coverage_result
  parse_tree = Parser::CurrentRuby.parse(ruby_source)
  cleaner = CoverageCleaner.new(coverage_result)
  cleaned = cleaner.process(parse_tree)
  puts Unparser.unparse(cleaned)
end
