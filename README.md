# CoherenceOauth2

[![Build Status](https://travis-ci.org/danschultzer/coherence_oauth2.svg?branch=master)](https://travis-ci.org/danschultzer/coherence_oauth2)

Use OAuth 2 providers (google, github, twitter, facebook, etc) to login with your Coherence supported Phoenix app.

## Features

* Collects required login field if missing from oauth provider
  * Or if not verified in case of email
* Multiple providers can be used for accounts
* Github, Google, Twitter and Facebook handlers included
* Updates Coherence templates automatically

## Installation

Add CoherenceOauth2 to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # ...
    {:coherence_oauth2, git: "https://github.com/danschultzer/coherence_oauth2.git"}
    # ...
  ]
end
```

Run `mix deps.get` to install it.

Run to install coherence_oauth2:

```bash
mix coherence_oauth2.install
```

Set up routes:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use Coherence.Router
  use CoherenceOauth2.Router   # Add this

  scope "/", MyAppWeb do
    pipe_through [:browser, :public]
    coherence_routes()
    coherence_oauth2_routes() # Add this
  end

  # ...
end
```

The following OAuth 2.0 routes will now be available in your app:

```
coherence_oauth2_auth_path          GET    /auth/:provider            AuthorizationController :new
coherence_oauth2_auth_path          GET    /auth/:provider/callback   AuthorizationController :create
coherence_oauth2_registration_path  GET    /auth/:provider/new        RegistartionController  :add_login_field
coherence_oauth2_registration_path  GET    /auth/:provider/create     RegistartionController  :create
```

## Setting up OAuth client

Add the following to `config/config.exs`:

```elixir
config :coherence_oauth2, :providers,
       [
         github: [
           client_id: "REPLACE_WITH_CLIENT_ID",
           client_secret: "REPLACE_WITH_CLIENT_SECRET",
           handler: CoherenceOauth2.Github
        ]
      ]
```

Handlers for Twitter, Facebook, Google and Github are included. You can also add your own. The general structure of the handler looks like the following:

```elixir
defmodule TestProvider do
  def client(config) do
    config
    %{
      strategy: OAuth2.Strategy.AuthCode,
      site: "http://localhost:4000/",
      authorize_url: "http://localhost:4000/oauth/authorize",
      token_url: "http://localhost:4000/oauth/access_token"
    }
    |> Map.merge(config)
    |> OAuth2.Client.new()
  end

  def authorize_url!(client, params \\ []) do
    params = Keyword.merge(params, [scope: "user"])

    OAuth2.Client.authorize_url!(client, params)
  end

  def get_user(client, headers \\ [], params \\ []) do
    client
    |> OAuth2.Client.get("/user", headers, params)
    |> normalize(client)
  end

  def normalize({:ok, %OAuth2.Response{body: user}}) do
    {:ok, user}
  end
end
```

## LICENSE

(The MIT License)

Copyright (c) 2017 Dan Schultzer & the Contributors Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
