require 'byebug'

# finds all surfaces that are defined as a floor
def find_floor_surfaces(idf_objects)
	floor_surfaces =[]

	surfaces = idf_objects.objects.select{ |obj| obj.kind_of?(EnergyPlusObject) && obj.name == 'BuildingSurface:Detailed'}

	surfaces.each do |surface|
		if surface.attributes.select{ |attr| attr.value.downcase == "floor" } != [] then floor_surfaces << surface end
	end
	floor_surfaces
end

# filter and re-structure floor surface attributes
def filter_and_restructure_surface_attributes(floor_surfaces)
	restructured_surfaces = []

	floor_surfaces.each do |surface|
		zone_object = {}

		zone_object[:zone_name] = surface.attributes.select{ |attr| attr.name == "Zone Name"}.first[:value]
		zone_object[:surface_id] = surface.attributes.select{ |attr| attr.name == "Name"}.first[:value]
		
		zone_object[:vertexes] = []

		vertex_attributes = surface.attributes.select{ |attr| attr.name.include? "Vertex"}

		vertex_attributes.each do |vertex|
			zone_object[:vertexes] << vertex.value.split(',').collect{|v| v.strip.to_f.round(10) }
		end
		restructured_surfaces << zone_object
	end
	restructured_surfaces
end

# translate geometry into positive cooridinates
def translate_surfaces_and_find_max_dimensions(zones)
	min_x_dimension = 0
	min_y_dimension = 0

	max_x_dimension = 0
	max_y_dimension = 0

	zones.each do |zone|
		zone[:vertexes].each do |vertex|
			if vertex[0] < min_x_dimension then min_x_dimension = vertex[0] end
			if vertex[1] < min_y_dimension then min_y_dimension = vertex[0] end

			if vertex[0] > max_x_dimension then max_x_dimension = vertex[0] end
			if vertex[1] > max_y_dimension then max_y_dimension = vertex[0] end
		end
	end

	zones.each do |zone|
		zone[:vertexes].each do |vertex|
			vertex[0] =  vertex[0] + min_x_dimension.abs
			vertex[1] =  vertex[1] + min_y_dimension.abs
		end
	end

	max_x_dimension = max_x_dimension + min_x_dimension.abs
	max_y_dimension = max_y_dimension + min_y_dimension.abs

	{max_x: max_x_dimension, max_y: max_y_dimension}
end

def assign_floor_names(floor_height_array)
	floor_dictionary = []
	positive_floors = []
	negative_floors = []

	# split and sort negative and positive floors
	floor_height_array.each do |floor_height|
		if floor_height < 0 then negative_floors << floor_height end
		if floor_height >= 0 then positive_floors << floor_height end
	end

	negative_floors.sort! { |a, z| z <=> a }
	positive_floors.sort!
	floor_height_array.sort!

	# assign floor names
	floor_height_array.each_with_index do |floor_height,i|
		if floor_height < 0
			floor_dictionary << { 
				floor_height: floor_height,
				floor_name: "Basement #{negative_floors.index(floor_height) - 1}",
				floor_index: i,
				zones: []
			}
		else
			floor_dictionary << { 
				floor_height: floor_height,
				floor_name: "Floor #{positive_floors.index(floor_height) + 1}",
				floor_index: i,
				zones: []
			}
		end
	end
	floor_dictionary
end

# normalize dimensions from 0-1
def normalize_dimensions(max_x,max_y,zones)
	zones.each do |zone|
		zone[:vertexes].each do |vertex|
			vertex[0] =  vertex[0] / max_x
			vertex[1] =  vertex[1] / max_y
		end
	end
end

# find and assign floors
def find_assign_and_organize_zones_by_floor(zones)
	floor_heights = []
	zones_by_floor = []

	# find unique floor heights
	zones.each do |zone|
		zone_z_dimension_array = []
		zone[:vertexes].each do |vertex|
			zone_z_dimension_array << vertex[2]
		end

		# need to make sure all of the floor heights are the same
		if zone_z_dimension_array.uniq.length == 1
			if ! floor_heights.include? zone_z_dimension_array[0] then floor_heights << zone_z_dimension_array[0] end
		else
			puts "mismatched floor heights on #{zone[:zone_name]} #{zone[:surface_id]}"
		end
	end

	# assign floor heights a name
	zones_by_floor = assign_floor_names(floor_heights)

	# organize zones by floor
	zones.each do |zone|
		zones_by_floor.each do |floor|
			if zone[:vertexes].first[2] == floor[:floor_height]
				floor[:zones] << zone
			end
		end
	end
	zones_by_floor
end
