require 'erb'
require 'byebug'
require 'kirinki'
require_relative 'geometry_functions.rb'
require 'json'

include Kirinki
@idf_objects = Parser.new('idf/city_west_4.idf').objects

floor_surfaces = find_floor_surfaces(@idf_objects)
zones = filter_and_restructure_surface_attributes(floor_surfaces)
max_dimensions = translate_surfaces_and_find_max_dimensions(zones)

normalize_dimensions(max_dimensions[:max_x],max_dimensions[:max_y],zones)

zones_by_floor = find_assign_and_organize_zones_by_floor(zones)

html_template = ERB.new(File.read('welcome-to-the-matrix.html.erb'))
file = File.open("welcome-to-the-matrix.html", "w")
file.write(html_template.result(binding))
file.close
