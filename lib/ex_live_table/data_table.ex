defmodule ExLiveTable.DataTable do
  @moduledoc """
  Provides helper functions for table sorting, pagination, and query string operations.
  """
  use Phoenix.Component
  import Phoenix.LiveView.Helpers

  @doc """
  Parses sort parameters from URL query parameters.
  Returns a tuple of {sort_direction, sort_field}.

  ## Examples

      iex> sort(%{"sort_field" => "name", "sort_direction" => "asc"})
      {:asc, :name}

      iex> sort(%{"sort_field" => "created_at", "sort_direction" => "desc"})
      {:desc, :created_at}

      iex> sort(%{})
      {:asc, :id}
  """
  def sort(%{"sort_field" => field, "sort_direction" => direction})
      when direction in ~w(asc desc) do
    {String.to_atom(direction), String.to_existing_atom(field)}
  end

  def sort(_other) do
    {:asc, :id}
  end

  @doc """
  Creates a table header link for sorting with proper direction switching.

  ## Examples

      iex> table_link(%{"sort_field" => "name", "sort_direction" => "asc"}, "Name", :name)
      # Returns a LiveView link to sort by name in desc order
  """
  def table_link(params, text, field) do
    direction = params["sort_direction"]

    opts =
      if params["sort_field"] == to_string(field) do
        [
          sort_field: field,
          sort_direction: reverse(direction)
        ]
      else
        [
          sort_field: field,
          sort_direction: "desc"
        ]
      end

    querystring = querystring(params, opts)

    live_patch(text, to: "?" <> querystring)
  end

  @doc """
  Builds a query string from the current params and options.
  Used for pagination and sorting links.

  ## Examples

      iex> querystring(%{"page" => "1"}, sort_field: :name, sort_direction: "desc")
      "page=1&sort_field=name&sort_direction=desc"
  """
  def querystring(params, opts \\ %{}) do
    params =
      params
      |> Plug.Conn.Query.encode()
      |> URI.decode_query()

    opts = %{
      # For the pagination
      "page" => opts[:page],
      "sort_field" => opts[:sort_field] || params["sort_field"] || nil,
      "sort_direction" => opts[:sort_direction] || params["sort_direction"] || nil
    }

    params
    |> Map.merge(opts)
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
    |> URI.encode_query()
  end

  @doc """
  Reverses the sort direction.
  """
  defp reverse("desc"), do: "asc"
  defp reverse(_), do: "desc"

  @doc """
  Handles the empty table state, displaying a loading spinner or "No data" message.
  """
  attr(:data_loader, :boolean, default: true)
  def empty_table(assigns) do
    ~H"""
    <tr style="text-align: center">
      <%= if @data_loader do %>
        <td valign="top" colspan="20" class="text-center">
          <div class="text-center">
            <div role="status">
              <svg
                aria-hidden="true"
                class="inline w-8 h-8 mr-2 text-gray-200 animate-spin fill-blue-600"
                viewBox="0 0 100 101"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                  fill="currentColor"
                />
                <path
                  d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                  fill="currentFill"
                />
              </svg>
              <span class="sr-only">Loading...</span>
            </div>
          </div>
        </td>
      <% else %>
        <%= if Enum.empty?(@data) do %>
          <td valign="top" colspan="20" class="text-rose-500 p-3">No data available in table</td>
        <% end %>
      <% end %>
    </tr>
    """
  end

  @doc """
  Renders a search input box that triggers an "iSearch" event on change.
  """
  attr(:params, :map, default: %{"filter" => %{"isearch" => ""}})
  def isearch(assigns) do
    ~H"""
    <form class="max-w-sm my-2" phx-change="iSearch">
      <div class="relative formkit-field">
        <label for="member_email" class="hidden block mb-2 text-sm font-medium text-gray-900">
          Search
        </label>

        <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none text-gray-300">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
        </div>

        <input
          type="search"
          class="formkit-input brand-input !pl-12"
          value={@params["filter"]["isearch"]}
          name="isearch"
          placeholder="Search..."
          aria-describedby="basic-addon3"
        />
      </div>
    </form>
    """
  end
end
