defmodule Infusion.LoggerChannel do
  use Phoenix.Channel
  require Logger

  def join("logger", _message, socket) do
    Consumer.start_link
    {:ok, socket}
  end

  def terminate(reason, socket) do
    :ok
  end

end
