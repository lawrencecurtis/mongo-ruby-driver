# encoding: UTF-8
#
# --
# Copyright (C) 2008-2011 10gen Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ++

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

MINIMUM_BSON_EXT_VERSION = "1.5.0.rc0"

module BSON
  VERSION = "1.5.0.rc0"

  if defined? Mongo::DEFAULT_MAX_BSON_SIZE
    DEFAULT_MAX_BSON_SIZE = Mongo::DEFAULT_MAX_BSON_SIZE
  else
    DEFAULT_MAX_BSON_SIZE = 4 * 1024 * 1024
  end

  def self.serialize(obj, check_keys=false, move_id=false)
    BSON_CODER.serialize(obj, check_keys, move_id)
  end

  def self.deserialize(buf=nil)
    BSON_CODER.deserialize(buf)
  end

  # Reads a single BSON document from an IO object.
  # This method is used in the executable b2json, bundled with
  # the bson gem, for reading a file of bson documents.
  #
  # @param [IO] io an io object containing a bson object.
  #
  # @return [ByteBuffer]
  def self.read_bson_document(io)
    bytebuf = BSON::ByteBuffer.new
    sz = io.read(4).unpack("V")[0]
    bytebuf.put_int(sz)
    bytebuf.put_array(io.read(sz-4).unpack("C*"))
    bytebuf.rewind
    return BSON.deserialize(bytebuf)
  end
end

if RUBY_PLATFORM =~ /java/
  jar_dir = File.join(File.dirname(__FILE__), '..', 'ext', 'java', 'jar')
  require File.join(jar_dir, 'mongo-2.6.5.jar')
  require File.join(jar_dir, 'jbson.jar')
  require 'bson/bson_java'
  module BSON
    BSON_CODER = BSON_JAVA
  end
else
  begin
    # Need this for running test with and without c ext in Ruby 1.9.
    raise LoadError if ENV['TEST_MODE'] && !ENV['C_EXT']

    # Raise LoadError unless little endian
    raise LoadError unless "\x01\x00\x00\x00".unpack("i").first == 1

    require 'bson_ext/cbson'
    raise LoadError unless defined?(CBson::VERSION)
    if CBson::VERSION < MINIMUM_BSON_EXT_VERSION
      puts "Able to load bson_ext version #{CBson::VERSION}, but >= #{MINIMUM_BSON_EXT_VERSION} is required."
      raise LoadError
    end
    require 'bson/bson_c'
    module BSON
      BSON_CODER = BSON_C
    end
  rescue LoadError
    require 'bson/bson_ruby'
    module BSON
      BSON_CODER = BSON_RUBY
    end
    unless ENV['TEST_MODE']
      warn "\n**Notice: C extension not loaded. This is required for optimum MongoDB Ruby driver performance."
      warn "  You can install the extension as follows:\n  gem install bson_ext\n"
      warn "  If you continue to receive this message after installing, make sure that the"
      warn "  bson_ext gem is in your load path and that the bson_ext and mongo gems are of the same version.\n"
    end
  end
end

require 'bson/types/binary'
require 'bson/types/code'
require 'bson/types/dbref'
require 'bson/types/object_id'
require 'bson/types/min_max_keys'
require 'bson/types/timestamp'

require 'base64'
require 'bson/ordered_hash'
require 'bson/byte_buffer'
require 'bson/bson_ruby'
require 'bson/exceptions'
