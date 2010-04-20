#	This file is part of the "Utopia Framework" project, and is licensed under the GNU AGPLv3.
#	Copyright 2010 Samuel Williams. All rights reserved.
#	See <utopia.rb> for licensing details.

require 'pathname'

Pathname.new(__FILE__).dirname.entries.grep(/\.rb$/).each do |path|
	name = File.basename(path.to_s, ".rb")
	
	if name != "all"
		require "utopia/tags/#{name}"
	end
end

