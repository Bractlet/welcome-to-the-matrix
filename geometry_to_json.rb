require 'erb'
require 'byebug'

geometry = File.open('geometry-raw.txt')

surface_name_line_number = 0
surface_type_line_number = 0
zone_name_line_number = 0
first_vertex_line_number = 0 
vertex_line_number = 0
surface_name = ""
surface_type = ""

geometry_hash = []

geometry.each_with_index do |line,index|
	if line == "BuildingSurface:Detailed,\n"
		surface_name_line_number = index + 1
	end

	if (index == surface_name_line_number) && (index !=0)
		surface_name = line.scan(/\s\s(.*?),/).last.first
		surface_type_line_number = index + 1
	end

	if (index == surface_type_line_number) && (index != 0)
		surface_type = line.scan(/\s\s(.*?),/).last.first

		if surface_type == "Floor"
			zone_name_line_number = index + 2
		end
	end

	if (index == zone_name_line_number) && (index != 0)
		geometry_hash << {
			surface_name: surface_name,
			zone_name: line.scan(/\s\s(.*?),/).last.first
		}
		first_vertex_line_number = index + 7
	end

	if (index == first_vertex_line_number) && (index != 0)
		hash_index = geometry_hash.length - 1
		vertex = line.scan(/\s\s(.*?)(,|;)(\s*)!/).last.first.split(/\s*,\s*/)
		geometry_hash[hash_index][:vertexes] = [{x: vertex[0].to_f, y: vertex[1].to_f, z: vertex[2].to_f}]
		vertex_line_number = first_vertex_line_number + 1
	end

	if (index == vertex_line_number) && (index != 0)
		if line.include? "X,Y,Z"
			hash_index = geometry_hash.length - 1
			vertex = line.scan(/\s\s(.*?)(,|;)(\s*)!/).last.first.split(/\s*,\s*/)
			geometry_hash[hash_index][:vertexes] << {x: vertex[0].to_f, y: vertex[1].to_f, z: vertex[2].to_f}
			vertex_line_number += 1
		end
	end
end


# geometry_hash.each do |surface_object|
# 	surface_string_string = "{surface_name:
# 	surface_string << 
	
# end


html_template = ERB.new(File.read('welcome-to-the-matrix.html.erb'))
file = File.open("welcome-to-the-matrix.html", "w")
file.write(html_template.result(binding))
file.close
