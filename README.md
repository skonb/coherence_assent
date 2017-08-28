# CoherenceOauth2

[![Build Status](https://travis-ci.org/danschultzer/coherence_oauth2.svg?branch=master)](https://travis-ci.org/danschultzer/coherence_oauth2)

Use google, github, twitter, facebook or any other OAuth 2 provider to login with your Coherence supported Phoenix app.

## Installation

Add CoherenceOauth2 to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # ...
    {:coherence_oauth2, "~> 0.1.0"}
    # ...
  ]
end
```

Run `mix deps.get` to install it.

Add migrations and set up `config/config.exs`:

```bash
mix coherence_oauth2.install
```

Set up routes:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use CoherenceOauth2.Router

  scope "/", MyAppWeb do
    coherence_oauth2_routes
  end

  # ...
end
```

That's it! The following OAuth 2.0 routes will now be available in your app:

```
auth_provider_path  GET    /auth/:provider         AuthorizationController :new
callback_auth_provider_path  POST   /oauth/:provider/callback         AuthorizationController :create
```

## LICENSE

(The MIT License)

Copyright (c) 2017 Dan Schultzer & the Contributors Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
