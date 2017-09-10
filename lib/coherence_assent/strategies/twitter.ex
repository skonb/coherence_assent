defmodule CoherenceAssent.Strategy.Twitter do
  alias CoherenceAssent.Strategy.Helpers
  alias CoherenceAssent.Strategies.Oauth, as: OauthHelper

  def authorize_url(conn: conn, config: config) do
    config = config |> set_config
    OauthHelper.authorize_url(conn: conn, config: config)
  end

  def callback(conn: conn, config: config, params: params) do
    config = config |> set_config
    OauthHelper.callback(conn: conn, config: config, params: params)
    |> normalize
  end

  defp set_config(config) do
    [
      site: "https://api.twitter.com",
      user_url: "/1.1/account/verify_credentials.json?include_entities=false&skip_status=true&include_email=true",
    ]
    |> Keyword.merge(config)
  end

  defp normalize({:ok, %{conn: conn, user: user}}) do
    user = %{"uid"         => Integer.to_string(user["id"]),
             "nickname"    => user["screen_name"],
             "email"       => user["email"],
             "location"    => user["location"],
             "name"        => user["name"],
             "image"       => user["profile_image_url_https"],
             "description" => user["description"],
             "urls"        => %{"Website" => user["url"],
                                "Twitter" => "https://twitter.com/#{user["screen_name"]}"}}
           |> Helpers.prune

    {:ok, %{conn: conn, user: user}}
  end
  defp normalize({:error, _} = error), do: error
end
