# Copyright, 2014, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Utopia
	class Session
		# A simple hash table which fetches it's values only when required.
		class LazyHash
			def initialize(&block)
				@changed = false
				@invalidate = false
				@values = nil
				
				@loader = block
			end
			
			attr :values
			
			def [] key
				load![key]
			end
			
			def []= key, value
				values = load!
				
				if values[key] != value
					values[key] = value
					@changed = true
				end
				
				return value
			end
			
			def include?(key)
				load!.include?(key)
			end
			
			def delete(key)
				load!
				
				@changed = true if @values.include? key
				
				@values.delete(key)
			end

			def invalidate!
				# tell the user agent to expire the cookie as per RFC 6265
				@invalidate = true
			end

			def invalidated?
				@invalidate
			end
			
			def changed?
				@changed
			end
			
			def load!
				@values ||= @loader.call
			end
			
			def loaded?
				!@values.nil?
			end
			
			def needs_update?(timeout = nil)
				# If data has changed, we need update:
				return true if @changed
				
				# We want to be careful here and not call load! which isn't cheap operation.
				if timeout and @values and updated_at = @values[:updated_at]
					# If the last update was too long ago, we need update:
					return true if updated_at < (Time.now - timeout)
				end
				
				return false
			end
		end
	end
end
