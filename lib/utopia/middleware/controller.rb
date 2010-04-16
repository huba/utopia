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
require 'utopia/path'

class Rack::Request
	def controller(&block)
		if block_given?
			env["utopia.controller"].instance_eval(&block)
		else
			env["utopia.controller"]
		end
	end
end

module Utopia
	module Middleware

		class Controller
			CONTROLLER_RB = "controller.rb"

			class Variables
				def [](key)
					instance_variable_get("@#{key}")
				end
				
				def []=(key, value)
					instance_variable_set("@#{key}", value)
				end
			end

			class Base
				def initialize(controller)
					@controller = controller
					@actions = {}

					methods.each do |method_name|
						next unless method_name.match(/on_(.*)$/)

						action($1.split("_")) do |path, request|
							# LOG.debug("Controller: #{method_name}")
							self.send(method_name, path, request)
						end
					end
				end

				def action(path, options = {}, &block)
					cur = @actions

					path.reverse.each do |name|
						cur = cur[name] ||= {}
					end

					cur[:action] = Proc.new(&block)
				end

				def lookup(path)
					cur = @actions

					path.components.reverse.each do |name|
						cur = cur[name]

						return nil if cur == nil

						if action = cur[:action]
							return action
						end
					end
				end

				# Given a request, call an associated action if one exists
				def passthrough(path, request)
					action = lookup(path)

					if action
						action.call(path, request)
					else
						return nil
					end
				end
				
				def permission_denied
					[403, {}, ["Permission Denied!"]]
				end

				def call(env)
					@controller.app.call(env)
				end

				def redirect(target, status=302)
					Rack::Response.new([], status, "Location" => target.to_s).finish
				end

				def permission_denied
					[403, {}, ["Permission Denied!"]]
				end

				def process!(path, request)
				end
				
				def self.require_local(path)
					require(File.join(const_get('BASE_PATH'), path))
				end
			end

			def initialize(app, options = {})
				@app = app
				@root = options[:root] || Utopia::Middleware::default_root

				LOG.info "#{self.class.name}: Running in #{@root}"

				@controllers = {}
				@cache_controllers = true

				if options[:controller_file]
					@controller_file = options[:controller_file]
				else
					@controller_file = "controller.rb"
				end
			end

			attr :app

			def lookup(path)
				if @cache_controllers
					return @controllers.fetch(path.to_s) do |key|
						@controllers[key] = load_file(path)
					end
				else
					return load_file(path)
				end
			end

			def load_file(path)
				if path.directory?
					base_path = File.join(@root, path.components)
				else
					base_path = File.join(@root, path.dirname.components)
				end

				controller_path = File.join(base_path, CONTROLLER_RB)

				if File.exist?(controller_path)
					klass = Class.new(Base)
					klass.const_set('BASE_PATH', base_path)
					
					$LOAD_PATH.unshift(base_path)
					
					klass.class_eval(File.read(controller_path), controller_path)
					
					$LOAD_PATH.delete(base_path)
					
					return klass.new(self)
				else
					return nil
				end
			end

			def fetch_controllers(path)
				controllers = []
				path.ascend do |parent_path|
					controllers << lookup(parent_path)
				end

				return controllers.compact.reverse
			end

			def call(env)
				env["utopia.controller"] ||= Variables.new
				
				request = Rack::Request.new(env)

				path = Path.create(request.path_info)
				fetch_controllers(path).each do |controller|
					if result = controller.process!(path, request)
						return result
					end
				end

				return @app.call(env)
			end
		end

	end
end