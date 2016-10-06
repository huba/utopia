# ![Utopia](materials/utopia.png?raw=true)

Utopia is a website generation framework which provides a robust set of tools
to build highly complex dynamic websites. It uses the filesystem heavily for
content and provides functions for interacting with files and directories as
structure representing the website.

[![Build Status](https://secure.travis-ci.org/ioquatix/utopia.svg)](http://travis-ci.org/ioquatix/utopia)
[![Code Climate](https://codeclimate.com/github/ioquatix/utopia.svg)](https://codeclimate.com/github/ioquatix/utopia)
[![Coverage Status](https://coveralls.io/repos/ioquatix/utopia/badge.svg)](https://coveralls.io/r/ioquatix/utopia)

## Installation

### Local Setup

Install utopia:

	$ gem install utopia

Create a new site:

	$ mkdir www.example.com
	$ cd www.example.com
	$ utopia site create
	$ rake

#### Bower Integration

If you create a site using the utopia generator, it includes a `.bowerrc` configuration which installs components into `public/_static/components`. To install jquery, for example:

	$ bower install jquery

Then add the appropriate `<script>` tags to `pages/_page.xnode`:

	<script src="/_static/components/jquery/dist/jquery.min.js" type="text/javascript"></script>

### Server Setup

Utopia can be used to set up remote sites quickly and easily.

Firstly log into your remote site using `ssh` and install utopia:

	$ ssh remote
	$ sudo gem install utopia

Then use the utopia command to generate a new remote site:

	$ mkdir /srv/http/www.example.com
	$ cd /srv/http/www.example.com
	$ sudo -u http utopia server create

On the local site, you can set up a git remote:

	$ git remote add production ssh://remote/srv/http/www.example.com
	$ git push --set-upstream production master

### Passenger+Nginx Setup

Utopia works well with Passenger+Nginx. Installing Passenger+Nginx is easy:

	$ ssh remote
	$ sudo gem install passenger
	$ passenger-install-nginx-module

Then, Nginx is configured like so:

	server {
		listen 80;
		server_name www.example.com;
		root /srv/http/www.example.com/public;
		passenger_enabled on;
	}

	server {
		listen 80;
		server_name example.com;
		rewrite ^ http://www.example.com$uri permanent;
	}

### Arch Linux

Packages for deploying Passenger+Nginx on Arch are available in the AUR. There are issues with the official packages so please avoid them.

- [nginx-mainline-passenger](https://aur.archlinux.org/packages/nginx-mainline-passenger/)
- [passenger-nginx-module](https://aur.archlinux.org/packages/passenger-nginx-module/)

#### Compression

We suggest [enabling gzip compression](https://zoompf.com/blog/2012/02/lose-the-wait-http-compression):

	gzip on;
	gzip_vary on;
	gzip_comp_level 6;
	gzip_http_version 1.1;
	gzip_proxied any;
	gzip_types text/* image/svg+xml application/json application/javascript;

## Usage

Utopia builds on top of Rack with the following middleware:

- `Utopia::Static`: Serve static files efficiently.
- `Utopia::Redirection`: Redirect URL patterns and status codes.
- `Utopia::Localization`: Non-intrusive localization of resources.
- `Utopia::Controller`: Dynamic behaviour with recursive execution.
- `Utopia::Content`: XML-style template engine with powerful tag behaviours.
- `Utopia::Session::EncryptedCookie`: Session storage using an encrypted cookie.

### Static

This middleware serves static files using the `mime-types` library. By default, it works with `Rack::Sendfile` and supports `ETag` based caching. Normally, you'd prefer to put static files into `public/_static` but it's also acceptable to put static content into `pages/` if it makes sense.

### Redirection

A set of flexible URI rewriting middleware which includes support for string mappings, regular expressions and status codes (e.g. 404 errors).

### Localization

The localization middleware uses the `Accept-Language` header to guess the preferred locale out of the given options. If a request path maps to a resource, that resource is returned. Otherwise, a localized request is made.

### Controller

A simple recursive controller layer which works in isolation from the view rendering middleware. A controller consists of a set of actions which match against incoming paths and execute code accordingly.

### Content

A tag based content generation system which integrates nicely with HTML5. Supports structures which separate generic page templates from dynamically generated content in an easy and consistent way.

### Session

The encrypted cookie session management uses symmetric private key encryption to store data on the client and avoid tampering.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT license.

Copyright, 2015, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
