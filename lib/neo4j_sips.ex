defmodule Neo4j.Sips do
  @moduledoc """
  A module that provides a simple Interface to communicate with a
  Neo4j server via REST. All functions take a pool to run the query on.

  """

  alias Neo4j.Sips.Transaction
  alias Neo4j.Sips.Connection
  alias Neo4j.Sips.Query

  @config Application.get_env(:neo4j_sips, Neo4j)
  @version "0.1.0"
  @pool_name :neo4j_sips_pool

  if !@config, do: raise "Neo4j.Sips is not configured"
  if !Dict.get(@config, :url), do: raise "Neo4j.Sips requires the :url of the database"

  def version do
    @version
  end

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    ConCache.start_link([], name: :neo4j_sips_cache)

    poolboy_config = [
      name: {:local, @pool_name},
      worker_module: Neo4j.Sips.Connection,
      size: config(:pool_size),
      max_overflow: config(:max_overflow)
    ]

    children = [
      :poolboy.child_spec(@pool_name, poolboy_config, config)
    ]

    opts = [strategy: :one_for_one, name: Neo4j.Supervisor]
    Supervisor.start_link(children, opts)
  end

  ## Connection

  defdelegate conn(), to: Connection

  @doc """

  return the server version
  """
  @spec server_version() :: String.t
  defdelegate server_version(), to: Connection

  ## Query
  ########################

  @doc """
  sends the query (and its parameters) to the server and returns {:ok, Neo4j.Sips.Response} or
  {:error, error} otherwise
  """
  @spec query(Neo4j.Sips.Connection, String.t) :: {:ok, Neo4j.Sips.Response} | {:error, Neo4j.Sips.Error}
  defdelegate query(conn, statement), to: Query

  @doc """
  The same as query/2 but raises a Neo4j.Sips.Error if it fails.
  Returns the server response otherwise.
  """
  @spec query!(Neo4j.Sips.Connection, String.t) :: Neo4j.Sips.Response | Neo4j.Sips.Error
  defdelegate query!(conn, statement), to: Query

  @doc """
  send a query and an associated map of parameters. Returns the server response or an error
  """
  @spec query(Neo4j.Sips.Connection, String.t, Map.t) :: {:ok, Neo4j.Sips.Response} | {:error, Neo4j.Sips.Error}
  defdelegate query(conn, statement, params), to: Query

  @doc """
  The same as query/3 but raises a Neo4j.Sips.Error if it fails.
  """
  @spec query!(Neo4j.Sips.Connection, String.t, Map.t) :: Neo4j.Sips.Response | Neo4j.Sips.Error
  defdelegate query!(conn, statement, params), to: Query


  ## Transaction
  ########################

  @doc """
  begin a new transaction.
  """
  @spec tx_begin(Neo4j.Sips.Connection) :: Neo4j.Sips.Connection
  defdelegate tx_begin(conn), to: Transaction

  @doc """
  execute a Cypher statement in a new or an existing transaction
  begin a new transaction. If there is no need to keep a
  transaction open across multiple HTTP requests, you can begin a transaction,
  execute statements, and commit with just a single HTTP request.
  """
  @spec tx_commit(Neo4j.Sips.Connection, String.t) :: Neo4j.Sips.Response
  defdelegate tx_commit(conn, statements), to: Transaction

  @doc """
  given you have an open transaction, you can use this to send a commit request
  """
  @spec tx_commit(Neo4j.Sips.Connection) :: Neo4j.Sips.Response
  defdelegate tx_commit(conn), to: Transaction

  @doc """
  execute a Cypher statement with a map containing associated parameters
  """
  @spec tx_commit(Neo4j.Sips.Connection, String.t, Map.t) :: Neo4j.Sips.Response
  defdelegate tx_commit(conn, statement, params), to: Transaction

  @spec tx_commit!(Neo4j.Sips.Connection, String.t) :: Neo4j.Sips.Response
  defdelegate tx_commit!(conn, statements), to: Transaction

  @spec tx_commit!(Neo4j.Sips.Connection, String.t, Map.t) :: Neo4j.Sips.Response
  defdelegate tx_commit!(conn, statement, params), to: Transaction

  @doc """
  given that you have an open transaction, you can send a rollback request.
  The server will rollback the transaction. Any further statements trying to run
  in this transaction will fail immediately.
  """
  @spec tx_rollback(Neo4j.Sips.Connection) :: Neo4j.Sips.Connection
  defdelegate tx_rollback(conn), to: Transaction

  ########################
  # @doc false
  # def start do
  #   :application.ensure_all_started(:neo4j_sips)
  # end

  @doc false
  def config, do: @config

  @doc false
  def config(key), do: Dict.get(config, key)

  @doc false
  def config(key, default), do: Dict.get(config, key, default)

  def pool_name, do: @pool_name

end