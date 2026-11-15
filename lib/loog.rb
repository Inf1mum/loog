# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'logger'
require 'time'

# Loog is an object-oriented wrapper around Ruby Logger:
#
#  require 'loog'
#  log = Loog::VERBOSE
#  log.info('Hello, world!')
#
# For more information read
# {README}[https://github.com/yegor256/loog/blob/master/README.md] file.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2026 Yegor Bugayenko
# License:: MIT
module Loog
  COMPACT =
    proc do |severity, _time, _target, msg|
      prefix = ''
      case severity
      when 'ERROR', 'FATAL'
        prefix = 'E: '
      when 'DEBUG'
        prefix = 'D: '
      end
      message = msg.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      "#{prefix}#{message.rstrip.gsub("\n", "\n#{' ' * prefix.length}")}\n"
    end

  SHORT =
    proc do |_severity, _time, _target, msg|
      message = msg.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      "#{message.rstrip}\n"
    end

  FULL =
    proc do |severity, time, _target, msg|
      message = msg.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      format(
        "%<time>s %<severity>5s %<msg>s\n",
        time: time.utc.iso8601,
        severity: severity,
        msg: message.rstrip
      )
    end

  NULL = Logger.new($stdout)
  NULL.level = Logger::UNKNOWN
  NULL.freeze

  VERBOSE = Logger.new($stdout)
  VERBOSE.level = Logger::DEBUG
  VERBOSE.formatter = COMPACT
  VERBOSE.freeze

  REGULAR = Logger.new($stdout)
  REGULAR.level = Logger::INFO
  REGULAR.formatter = COMPACT
  REGULAR.freeze

  ERRORS = Logger.new($stdout)
  ERRORS.level = Logger::ERROR
  ERRORS.formatter = COMPACT
  ERRORS.freeze

  # Accumulator of everything. This class may be used
  # for testing, when it's necessary to accumulate all log
  # messages in one place and then "assert" the presence
  # of certain strings inside them.
  class Buffer < Logger
    # Ctor
    # @param [String] level The level of logging
    # @param [String] formatter The formatter
    def initialize(level: Logger::DEBUG, formatter: Loog::SHORT)
      @lines = []
      super(Device.new(@lines), level: level, formatter: formatter)
    end

    def to_s
      @lines.map { |s| s.dup.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') }.join
    end

    # In-memory log device, which receives fully formatted lines
    # from the Logger and accumulates them in the given array.
    class Device
      # Ctor
      # @param [Array] lines Where to accumulate formatted lines
      def initialize(lines)
        @lines = lines
      end

      # Capture one fully formatted line
      # @param [String] line The formatted line coming from the Logger
      def write(line)
        @lines.push(line)
        line.length
      end

      # Do nothing, in-memory lines have nothing to close
      def close; end
    end
  end
end
