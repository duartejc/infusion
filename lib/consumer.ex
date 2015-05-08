defmodule Consumer do
  use GenServer
  use AMQP
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @exchange    "info"
  @queue       "bizside"
  @queue_error "#{@queue}_error"

  def init(_opts) do
    {:ok, conn} = Connection.open("amqp://guest:guest@localhost")
    {:ok, chan} = Channel.open(conn)
    # Limit unacknowledged messages to 10
    #Basic.qos(chan, prefetch_count: 10)
    #Queue.declare(chan, @queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    #Queue.declare(chan, @queue)
    #Exchange.fanout(chan, @exchange, durable: true)
    #Queue.bind(chan, @queue, @exchange)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, @queue)
    {:ok, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered, app_id: app, exchange: exchange, timestamp: timestamp}}, chan) do
    spawn fn -> consume(chan, tag, redelivered, app, exchange, timestamp, payload) end
    {:noreply, chan}
  end

  defp consume(channel, tag, redelivered, app, exchange, timestamp, payload) do
    try do
      #Phoenix.Channel.broadcast("logger", "update", %{id: 1, content: "hello"})
      Infusion.Endpoint.broadcast! "logger", "update", %{app: app, level: exchange, timestamp: timestamp, content: payload}
    rescue
      exception ->
        Logger.error exception
        # Requeue unless it's a redelivered message.
        # This means we will retry consuming a message once in case of exception
        # before we give up and have it moved to the error queue
        Basic.reject channel, tag, requeue: not redelivered
        IO.puts "Error converting #{payload} to integer"
    end
  end
end
