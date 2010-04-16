# Copyright (c) 2010 Samuel Williams. Released under the GNU GPLv3.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'set'
require 'csv'

module Utopia
	
	# TimeStore is a very simple time oriented database. New entries 
	# are added in chronological order and it is not possible to change 
	# this behaviour, or remove old entries. It stores data in a CSV
	# format into a directory where each file represents a week in the 
	# year.
	#
	# The design of this class is to enable efficient logging of data
	# in a backup friendly file format (i.e. files older than one week
	# are not touched).
	#
	# Due to the nature of CSV data, a header must be specified. This
	# header can have columns added, but not removed. Columns not
	# specified in the header will not be recorded.
	#
	class TimeStore
		def initialize(path, header)
			@path = path

			header = header.collect{|name| name.to_s}

			@header_path = File.join(@path, "header.csv")

			if File.exist? @header_path
				@header = File.read(@header_path).split(",")
			else
				@header = []
			end

			diff = (Set.new(header) + "time") - @header

			if diff.size
				@header += diff.to_a.sort

				File.open(@header_path, "w") do |file|
					file.write(@header.join(","))
				end
			end
			
			@last_path = nil
			@last_file = nil
		end

		attr :header

		def path_for_time(time)
			return File.join(@path, time.strftime("%Y-%W") + ".csv")
		end

		def open(time, &block)
			path = path_for_time(time)

			if @last_path != path
				if @last_file
					@last_file.close
					@last_file = nil
				end

				@last_file = File.open(path, "a")
				@last_file.sync = true
				@last_path = path
			end

			yield @last_file

			#File.open(path_for_time(time), "a", &block)
		end

		def dump(values)
			row = @header.collect{|key| values[key.to_sym]}
			return CSV.generate_line(row)
		end

		def <<(values)
			time = values[:time] = Time.now

			open(time) do |file|
				file.puts(dump(values))
			end
		end
	end
	
end