defmodule LiveChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LiveChatWeb.Telemetry,
      LiveChat.Repo,
      {DNSCluster, query: Application.get_env(:live_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LiveChat.PubSub},
      # Start the Presence system
      LiveChatWeb.Presence,
      # Start a worker by calling: LiveChat.Worker.start_link(arg)
      # {LiveChat.Worker, arg},
      # Start to serve requests, typically the last entry
      LiveChatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
