# CoherenceAssent

[![Build Status](https://travis-ci.org/danschultzer/coherence_assent.svg?branch=master)](https://travis-ci.org/danschultzer/coherence_assent)

Use Google, Github, Twitter, Facebook, or add your own strategy for authorization to your Coherence Phoenix app.

## Features

* Collects required login field if missing from provider
  * Or if not verified in case of email
* Multiple providers can be used for accounts
* Github, Google, Twitter and Facebook strategies included
* Updates Coherence templates automatically
* Plug in custom strategies

## Installation

Add CoherenceAssent to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # ...
    {:coherence_assent, git: "https://github.com/danschultzer/coherence_assent.git"}
    # ...
  ]
end
```

Run `mix deps.get` to install it.

Run to install coherence_assent:

```bash
mix coherence_assent.install
```

Set up routes:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use Coherence.Router
  use CoherenceAssent.Router  # Add this

  scope "/", MyAppWeb do
    pipe_through [:browser, :public]
    coherence_routes()
    coherence_assent_routes() # Add this
  end

  # ...
end
```

The following routes will now be available in your app:

```
coherence_assent_auth_path          GET    /auth/:provider            CoherenceAssent.AuthorizationController :new
coherence_assent_auth_path          GET    /auth/:provider/callback   CoherenceAssent.AuthorizationController :create
coherence_assent_registration_path  GET    /auth/:provider/new        CoherenceAssent.RegistartionController  :add_login_field
coherence_assent_registration_path  GET    /auth/:provider/create     CoherenceAssent.RegistartionController  :create
```

## Setting up a provider

Add the following to `config/config.exs`:

```elixir
config :coherence_assent, :providers,
       [
         github: [
           client_id: "REPLACE_WITH_CLIENT_ID",
           client_secret: "REPLACE_WITH_CLIENT_SECRET",
           strategy: CoherenceAssent.Strategy.Github
        ]
      ]
```

Strategy for Twitter, Facebook, Google and Github are included. You can also add your own. The general structure of the strategy looks like the following:

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
