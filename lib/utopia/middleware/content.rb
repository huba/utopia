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

require 'utopia/middleware'
require 'utopia/link'
require 'utopia/path'
require 'utopia/tags'

require 'utopia/middleware/content/node'
require 'utopia/etanni'

module Utopia
	module Middleware
	
		class Content
			def initialize(app, options = {})
				@app = app

				@root = File.expand_path(options[:root] || Utopia::Middleware::default_root)
				
				LOG.info "#{self.class.name}: Running in #{@root}"

				# Set to hash to enable caching
				@nodes = {}
				@files = nil

				@tags = options[:tags] || {}
			end

			attr :root
			attr :passthrough

			def fetch_xml(path)
				read_file = lambda { TemplateCache.new(path, Etanni) }
				
				if @files
					@files.fetch(path) do
						@files[path] = read_file.call
					end
				else
					read_file.call
				end
			end

			# Look up a named tag such as <entry />
			def lookup_tag(name, parent_path)
				if @tags.key? name
					return @tags[name]
				elsif Utopia::Tags.all.key? name
					return Utopia::Tags.all[name]
				end
				
				if String === name && name.index("/")
					name = Path.create(name)
				end
				
				if Path === name
					name = parent_path + name
					name_path = name.components.dup
					name_path[-1] += ".xnode"
				else
					name_path = name + ".xnode"
				end

				parent_path.ascend do |dir|
					tag_path = File.join(root, dir.components, name_path)

					if File.exist? tag_path
						return Node.new(self, dir + name, parent_path + name, tag_path)
					end

					if String === name_path
						tag_path = File.join(root, dir.components, "_" + name_path)

						if File.exist? tag_path
							return Node.new(self, dir + name, parent_path + name, tag_path)
						end
					end
				end
				
				return nil
			end

			def lookup_node(request_path)
				name = request_path.basename
				name_xnode = name + ".xnode"

				node_path = File.join(@root, request_path.dirname.components, name_xnode)

				if File.exist? node_path
					return Node.new(self, request_path.dirname + name, request_path, node_path)
				end

				return nil
			end

			def call(env)
				request = Rack::Request.new(env)
				path = Path.create(request.path_info).to_absolute

				# Check if the request is to a non-specific index.
				name, extensions = path.basename.split(".", 2)
				directory_path = File.join(@root, path.dirname.components, name)

				if File.directory? directory_path
					return [307, {"Location" => path.dirname.join([name, "index.#{extensions}"]).to_s}, []]
				end

				# Otherwise look up the node
				node = lookup_node(path)

				if node
					if request.head?
						return [200, {}, []]
					else
						response = Rack::Response.new
						node.process!(request, response)
						return response.finish
					end
				else
					return @app.call(env)
				end
			end
		end
		
	end
end