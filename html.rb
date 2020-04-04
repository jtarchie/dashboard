# frozen_string_literal: true

require 'erb'
require_relative 'calculate'
require_relative 'render'

source_url = 'https://github.com/datasets/covid-19'
source_path = File.join(__dir__, 'dataset')

`git clone #{source_url} #{source_path}` unless Dir.exist?(source_path)

Dir.chdir(source_path) do
  `git pull`
end

calc = Calculate.from_csv(File.join(source_path, 'data', 'time-series-19-covid-combined.csv'))

erb = ERB.new(File.read(File.join(__dir__, 'layout.html.erb')))
docs_dir = File.join(__dir__, 'docs')

File.write(File.join(docs_dir, 'index.html'), erb.result(Render.new(calc).erb_binding))
calc.by_country.each do |calc|
  path = File.join(docs_dir, "#{calc.slug}.html")
  File.write(path, erb.result(Render.new(calc).erb_binding))
end
