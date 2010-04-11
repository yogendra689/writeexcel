# -*- coding: utf-8 -*-
require 'helper'
require 'stringio'

=begin
  def compare_file(expected, target)
    fh_e = File.open(expected, "r")
    fh_t = File.open(target, "r")
    while true do
      e1 = fh_e.read(1)
      t1 = fh_t.read(1)
      if e1.nil?
        assert( t1.nil?, "#{expexted} is EOF but #{target} is NOT EOF.")
        break
      elsif t1.nil?
        assert( e1.nil?, '#{target} is EOF but #{expected} is NOT EOF.')
        break
      end
      assert_equal(e1, t1, sprintf(" #{expected} = '%s' but #{target} = '%s'", e1, t1))
      break
    end
    fh_e.close
    fh_t.close
  end
=end

class TC_OLEStorageLite < Test::Unit::TestCase
  TEST_DIR    = File.expand_path(File.dirname(__FILE__))
  PERL_OUTDIR = File.join(TEST_DIR, 'perl_output')
  EXCEL_OUTDIR = File.join(TEST_DIR, 'excelfile')

  def setup
    @ole = OLEStorageLite.new
  end

  def teardown
  end

  def test_olestoragelite_new
    ole = OLEStorageLite.new
    assert_nil(ole.file)

    io = StringIO.new
    ole = OLEStorageLite.new(io)
    assert_equal(io, ole.file)

    file = 'test.ole'
    ole = OLEStorageLite.new(file)
    assert_equal(file, ole.file)

  end

  def test_asc2ucs
    result = @ole.asc2ucs('Root Entry')
    target = %w(
        52 00 6F 00 6F 00 74 00 20 00 45 00 6E 00 74 00 72 00 79 00
      ).join(" ")
    assert_equal(target, unpack_record(result))
  end

  def test_ucs2asc
    strings = [
        'Root Entry',
        ''
      ]
    strings.each do |str|
      result = @ole.ucs2asc(@ole.asc2ucs(str))
      assert_equal(str, result)
    end
  end

  def unpack_record(data)
    data.unpack('C*').map! {|c| sprintf("%02X", c) }.join(' ')
  end

end

class TC_OLEStorageLitePPSFile < Test::Unit::TestCase
  def setup
  end

  def teardown
  end

  def test_constructor
    data = [
        { :name => 'name', :data => 'data' },
        { :name => '',     :data => 'data' },
        { :name => 'name', :data => ''     },
        { :name => '',     :data => ''     },
      ]
    data.each do |d|
      olefile = OLEStorageLitePPSFile.new(d[:name])
      assert_equal(d[:name], olefile.name)
    end
    data.each do |d|
      olefile = OLEStorageLitePPSFile.new(d[:name], d[:data])
      assert_equal(d[:name], olefile.name)
      assert_equal(d[:data], olefile.data)
    end
  end

  def test_append_no_file
    olefile = OLEStorageLitePPSFile.new('name')
    assert_equal('', olefile.data)

    data = [ "data", "\r\n", "\r", "\n" ]
    data.each do |d|
      olefile = OLEStorageLitePPSFile.new('name')
      olefile.append(d)
      assert_equal(d, olefile.data)
    end
  end

  def test_append_tempfile
    data = [ "data", "\r\n", "\r", "\n" ]
    data.each do |d|
      olefile = OLEStorageLitePPSFile.new('name')
      olefile.set_file
      pps_file = olefile.pps_file

      olefile.append(d)
      pps_file.open
      pps_file.binmode
      assert_equal(d, pps_file.read)
    end
  end

  def test_append_stringio
    data = [ "data", "\r\n", "\r", "\n" ]
    data.each do |d|
      sio = StringIO.new
      olefile = OLEStorageLitePPSFile.new('name')
      olefile.set_file(sio)
      pps_file = olefile.pps_file

      olefile.append(d)
      pps_file.rewind
      assert_equal(d, pps_file.read)
    end
  end

  def unpack_record(data)
    data.unpack('C*').map! {|c| sprintf("%02X", c) }.join(' ')
  end

end