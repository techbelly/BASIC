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

  EMPTY = Object.new()

  def empty_node(c)
    c == EMPTY || (c.is_a?(Parser::AST::Node) && c.type == :begin && c.children.empty?)
  end

  def sole_branch(children)
    non_empty = children.select {|c| !empty_node(c) }
    if non_empty.length == 2
      return non_empty[1]
    end
  end

  def coverage_count(node)
    first_line, last_line = node.location.first_line-1, node.location.last_line
    coverage[first_line..last_line].compact.max || 0
  end

  def process(node)
    return node unless node.is_a? Parser::AST::Node
    return node unless node.location.expression
    puts node.parent
    if node.type != :begin && coverage_count(node) == 0
      print "SKIPPING", node
      return EMPTY
    end

    children = cleaned(node)

    return EMPTY if node.type == :def && empty_node(children[2])

    # if node.type == :if && sole_branch(children)
    #   branch = sole_branch(children)
    #   return branch if coverage_count(branch) == coverage_count(node)
    # end

    node.updated(node.type, children, {location: node.location})
  end

  def cleaned(nodes)
    nodes.to_a.map { |node| process(node) }.delete_if {|e| e == EMPTY }
  end
end

#paths.each do | path |
path = paths[6]
  ruby_source = File.read(path)
  coverage_result = coverage[path]
  puts "coverage", coverage_result.map.with_index{ |e, i| "#{i+1} #{e}"}
  parse_tree = Parser::CurrentRuby.parse(ruby_source)
  puts "parse_tree", parse_tree
  cleaner = CoverageCleaner.new(coverage_result)
  cleaned = cleaner.process(parse_tree)
  puts "cleaned_tree", cleaned
  puts Unparser.unparse(cleaned)
#end
