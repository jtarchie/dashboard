# frozen_string_literal: true

require 'chartkick'

class Render
  include Chartkick::Helper

  def initialize(calc)
    @calc = calc
  end

  def stat_card(number, message)
    <<~HTML
      <div class="col-sm-12 col-md-4 col-lg-2">
          <div class="card fluid">
              <h2>#{number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}</h2>
              <p>#{message}</p>
          </div>
      </div>
    HTML
  end

  def graph_card(title, data, options)
    options[:legend] = true
    <<~HTML
      <div class="col-sm-12 col-md-6 col-lg-6">
          <h2>#{title}</h2>
          #{column_chart data, options}
      </div>
    HTML
  end

  def line_card(title, data)
    <<~HTML
      <div class="col-sm-12 col-md-6 col-lg-6">
          <h2>#{title}</h2>
          #{line_chart data}
      </div>
    HTML
  end

  def erb_binding
    binding
  end
end
