require 'rubygems'
require 'mongo'
require 'extlib'
require 'json'
require 'mordor/version'
require 'mordor/config'
require 'mordor/collection'
require 'mordor/resource'

unless Object.const_defined?('BigDecimal')
  BigDecimal = Float
end

class Date
  def to_time(form = :utc)
    Time.send("#{form}", year, month, day)
  end

  def to_gm
    Time.gm(year, month, day).to_datetime
  end

  def to_local
    Time.local(year, month, day).to_datetime
  end

  def to_datetime
    DateTime.civil(self.year, self.mon, self.day)
  end

  def show(format = nil)
    case format
    when :human
      strftime("%d-%m-%Y")
    else
      to_s
    end
  end

  def full_string
    strftime("%A %d %B %Y")
  end
end

class DateTime
  def to_datetime
    self
  end

  def to_date
    Date.civil(self.year, self.mon, self.day)
  end

  def show(format = nil)
    case format
    when :human
      strftime("%d-%m-%Y %H:%M")
    when :full
      strftime("%d-%m-%Y %H:%M:%S")
    else
      to_s
    end
  end
end

class Time

  def to_date
    Date.civil(year, month, day)
  end if RUBY_VERSION < '1.8.6'

  def show(format = nil)
    return self.to_date.show(format) if [hour,min] == [0,0]
    case format
    when :human
      strftime("%d-%m-%Y %H:%m")
    when :full
      strftime("%d-%m-%Y %H:%M:%S")
    else
      to_s
    end
  end
end

module Mordor
  def connection
    @connection ||= Mongo::Connection.new(Mordor::Config[:hostname], Mordor::Config[:port])
    @connection.autenticate(Mordor::Config[:username], Mordor::Config[:password]) if Mordor::Config[:username]
    @connection.db(Mordor::Config[:database])
  end
  module_function :connection
end
