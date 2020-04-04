# frozen_string_literal: true

require 'json'
require 'csv'
require 'groupdate'

Value = Struct.new(
  :date,
  :country,
  :state,
  :lat,
  :long,
  :confirmed,
  :recovered,
  :deaths,
  keyword_init: true
)

ByDateValue = Struct.new(:value) do
  def sum(date)
    value.fetch(date, 0)
  end

  def /(other)
    values = value.map do |date, sum|
      [date, sum.to_f / other.sum(date).to_f]
    end.reject do |_, ratio|
      ratio.nan?
    end.to_h
    self.class.new(values)
  end

  def -(other)
    values = value.map do |date, sum|
      [date, sum.to_f - other.sum(date)]
    end.to_h
    self.class.new(values)
  end

  def map(&block)
    values = value.map do |date, sum|
      [date, block.call(sum)]
    end.to_h
    self.class.new(values)
  end

  def as_percent
    map { |v| (v * 100).truncate(2) }
  end

  def to_json(*_args)
    value.to_json
  rescue JSON::GeneratorError
    warn value.inspect
    raise
  end
end

class Calculate
  # columns: Date,Country/Region,Province/State,Lat,Long,Confirmed,Recovered,Deaths
  def self.from_csv(filename)
    values = CSV.read(filename, headers: true, converters: %i[numeric])
    values = values.map do |v|
      Value.new(
        date: Date.parse(v['Date']),
        country: v['Country/Region'] || '',
        state: v['Province/State'] || '',
        lat: v['Lat'].to_f,
        long: v['Long'].to_f,
        confirmed: v['Confirmed'].to_i,
        recovered: v['Recovered'].to_i,
        deaths: v['Deaths'].to_i
      )
    end
    new(values: values, name: 'World')
  end

  def initialize(values:, name:)
    @values = values
    @name = name
  end

  attr_reader :name

  def slug
    name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end

  def total_cases(type, date = most_recent_day)
    @values
      .select { |v| v.date == date }
      .sum { |v| v.send(type) }
  end

  def diff_cases(type)
    total_cases(type, most_recent_day) - total_cases(type, most_recent_day.prev_day)
  end

  def cases_by_date(type)
    ByDateValue.new(
      group_by_day
        .map do |date, rows|
          [
            date,
            rows.sum { |v| v.send(type) }
          ]
        end.to_h
    )
  end

  def by_country
    @values.group_by(&:country).map do |country, rows|
      self.class.new(values: rows, name: country)
    end
  end

  def daily_change
    [
      { name: 'Infections', data: daily_change_by_type(:confirmed) },
      { name: 'Deaths', data: daily_change_by_type(:deaths) },
      { name: 'Recoveries', data: daily_change_by_type(:recovered) }
    ]
  end

  def most_recent_day
    @most_recent_day ||= @values.max_by(&:date).date
  end

  private

  def daily_change_by_type(type)
    a = group_by_day.map do |date, rows|
      [date, Calculate.new(values: rows, name: name)]
    end.each_cons(2).map do |(y, t)|
      [t[0], t[1].total_cases(type) - y[1].total_cases(type)]
    end.to_h
  end

  def group_by_day
    @group_by_day ||= @values.group_by_day(&:date)
  end
end
