defmodule ExLiveTable do
  @moduledoc """
  ExLiveTable is a comprehensive data table solution for Phoenix LiveView applications.

  It provides responsive tables with built-in sorting, filtering, pagination, and export
  functionality. The table automatically adapts between desktop and mobile views.

  ## Features

  - Responsive design with desktop and mobile views
  - Sorting by columns
  - Quick search filter
  - Pagination with Scrivener integration
  - CSV/Excel/PDF export functionality
  - Customizable styling

  ## Basic Usage

  ```elixir
  <ExLiveTable.main_table id="users" rows={@users} params={@params}>
    <:col :let={user} label="ID"><%= user.id %></:col>
    <:col :let={user} label="Username"><%= user.username %></:col>
    <:action :let={user}>
      <button phx-click="edit" phx-value-id={user.id}>Edit</button>
    </:action>
  </ExLiveTable.main_table>
  ```

  ## LiveView Integration

  In your LiveView, handle the table events:

  ```elixir
  def handle_event("iSearch", %{"isearch" => search_term}, socket) do
    # Update your query with search term
    {:noreply, assign(socket, search_term: search_term)}
  end

  def handle_event("refresh_table", _, socket) do
    # Reload data
    {:noreply, assign(socket, users: reload_users())}
  end

  def handle_event("filter", _, socket) do
    # Show filter modal
    {:noreply, socket}
  end

  def handle_event("export", %{"file_type" => file_type}, socket) do
    # Handle export based on file_type (csv, xlsx, pdf)
    {:noreply, socket}
  end
  ```
  """

  # Convenience re-exports
  defdelegate main_table(assigns), to: ExLiveTable.MainTable

  # Data manipulation helpers
  defdelegate sort(params), to: ExLiveTable.DataTable
  defdelegate querystring(params, opts \\ %{}), to: ExLiveTable.DataTable
  defdelegate table_link(params, text, field), to: ExLiveTable.DataTable

  @doc """
  Handles sorting in your LiveView when using Ecto.

  Note: This function requires Ecto to be installed.

  ## Example usage in LiveView

  ```elixir
  def handle_params(params, _url, socket) do
    query = ExLiveTable.handle_sorting(User, params)
    users = Repo.paginate(query, params)

    {:noreply, assign(socket, users: users, params: params)}
  end
  ```
  """
  def handle_sorting(query, params) do
    if Code.ensure_loaded?(Ecto.Query) do
      {direction, field} = sort(params)

      require Ecto.Query
      Ecto.Query.order_by(query, [q], [{^direction, field(q, ^field)}])
    else
      raise "Ecto is not available. Please add :ecto to your dependencies to use this function."
    end
  end

  @doc """
  Handles search filtering in your LiveView when using Ecto.

  Note: This function requires Ecto to be installed.

  ## Example usage in LiveView

  ```elixir
  def handle_event("iSearch", %{"isearch" => search_term}, socket) do
    params = put_in(socket.assigns.params, ["filter", "isearch"], search_term)

    {:noreply, push_patch(socket, to: "?" <> ExLiveTable.querystring(params))}
  end
  ```
  """
  def handle_search(query, %{"filter" => %{"isearch" => search_term}}) when search_term != "" do
    if Code.ensure_loaded?(Ecto.Query) do
      search_term = "%#{search_term}%"

      require Ecto.Query

      # This is a generic implementation - customize for your specific models
      Ecto.Query.where(
        query,
        [q],
        ilike(q.name, ^search_term) or
        ilike(q.description, ^search_term) or
        fragment("?::text", q.id) == ^search_term
      )
    else
      raise "Ecto is not available. Please add :ecto to your dependencies to use this function."
    end
  end

  def handle_search(query, _params), do: query
end
