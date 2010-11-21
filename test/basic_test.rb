lib = File.expand_path("../../lib", __FILE__)
$:.unshift lib unless $:.include?(lib)

require "test/unit"
require "basic/interpreter"
require "stringio"

class BasicTest < Test::Unit::TestCase

  def capture(string)
    old_stdin, old_stdout = $stdin, $stdout
    lines = string.strip.split(/\n/).map{ |s| s.strip } + %w[EXIT]
    cmd = lambda{ lines.shift }
    output = ""
    $stdout = StringIO.new(output)
    Basic::Interpreter.run(cmd)
    $stdin, $stdout = old_stdin, old_stdout
    output.sub(/^READY\n/, "").strip
  end

  def blockquote(string)
    string.strip.gsub(/^\s+/, "")
  end

  def test_should_count_up_in_FOR_loop
    output = capture <<-'END'
      10 FOR I=1 TO 4
      20 PRINT I
      30 NEXT I
      RUN
    END
    assert_match /1\n2\n3\n4/, output
  end

  def test_should_list_program
    program = blockquote <<-'END'
      5 REM Comment
      40 PRINT "Verbatim string; has some noise!"
      70 PRINT
      80 LET C$=CHR$(64+INT(RND(1)*26+1))
      90 FOR G=1 TO 4
      100 INPUT G$
      110 IF G$=C$ THEN GOTO 210
      120 IF G$<C$ THEN PRINT "LATER";
      130 IF G$>C$ THEN PRINT "EARLIER";
      140 PRINT " THAN ";G$
    END
    expected = program
    actual = capture([program, "LIST"].join("\n"))
    assert_equal expected, actual, ["---- actual ----", actual, "---- expected ----", expected].join("\n\n")
  end

end
