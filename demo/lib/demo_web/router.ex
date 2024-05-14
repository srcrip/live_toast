defmodule DemoWeb.Router do
  use DemoWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {DemoWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/", DemoWeb do
    pipe_through(:browser)

    live("/", HomeLive)
    live("/why", HomeLive, :why)
    live("/installation", HomeLive, :installation)
    live("/recipes", HomeLive, :recipes)
    live("/customization", HomeLive, :customization)

    get("/demo", PageController, :home)
  end
end
