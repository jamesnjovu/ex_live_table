# ExLiveTable

A comprehensive DataTable solution for Phoenix LiveView applications with built-in sorting, filtering, pagination, and responsive design.

## Installation

The package can be installed by adding `ex_live_table` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_live_table, "~> 0.1.0"}
  ]
end
```

## Features

- Responsive design with desktop and mobile views
- Sorting by columns
- Quick search filter
- Pagination with Scrivener integration
- CSV/Excel/PDF export functionality
- Customizable styling

## Usage

```elixir
<ExLiveTable.main id="users" rows={@users} params={@params}>
  <:col :let={user} label="ID"><%= user.id %></:col>
  <:col :let={user} label="Username"><%= user.username %></:col>
  <:action :let={user}>
    <button phx-click="edit" phx-value-id={user.id}>Edit</button>
  </:action>
</ExLiveTable.main>
```

## Documentation

The docs can be found at [https://hexdocs.pm/ex_live_table](https://hexdocs.pm/ex_live_table).

# LiveTable Usage Guide

`LiveTable` is a comprehensive data table solution for Phoenix LiveView applications with built-in sorting, filtering, pagination, and responsive design.

## Basic Example

Here's a simple example of using LiveTable in your LiveView application:

### Live View Module

```elixir
defmodule MyAppWeb.UserLive.Index do
  use MyAppWeb, :live_view
  alias MyApp.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    params = params || %{}
    page = Accounts.list_users(params)

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:users, page)}
  end

  @impl true
  def handle_event("iSearch", %{"isearch" => search_term}, socket) do
    params = put_in(socket.assigns.params, ["filter", "isearch"], search_term)
    {:noreply, push_patch(socket, to: ~p"/users?#{params}")}
  end

  @impl true
  def handle_event("refresh_table", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/users?#{socket.assigns.params}")}
  end

  @impl true
  def handle_event("export", %{"file_type" => file_type}, socket) do
    # Export logic for CSV, Excel, or PDF
    users = Accounts.list_all_users(socket.assigns.params)
    
    case file_type do
      "csv" -> generate_csv(users)
      "xlsx" -> generate_xlsx(users)
      "pdf" -> generate_pdf(users)
    end
    
    {:noreply, socket}
  end
end
```

### LiveView Template

```heex
<h1 class="text-2xl font-bold mb-4">Users</h1>

<ExLiveTable.main_table id="users" rows={@users} params={@params}>
  <:col :let={user} label="ID"><%= user.id %></:col>
  <:col :let={user} label="Name"><%= user.name %></:col>
  <:col :let={user} label="Email"><%= user.email %></:col>
  <:col :let={user} label="Role"><%= user.role %></:col>
  <:col :let={user} label="Created">
    <%= Calendar.strftime(user.inserted_at, "%Y-%m-%d") %>
  </:col>
  
  <:action :let={user}>
    <div class="flex items-center space-x-2">
      <.link navigate={~p"/users/#{user}/edit"} class="text-blue-600 hover:text-blue-800">
        Edit
      </.link>
      <button phx-click="delete" phx-value-id={user.id} class="text-red-600 hover:text-red-800"
              data-confirm="Are you sure you want to delete this user?">
        Delete
      </button>
    </div>
  </:action>
</ExLiveTable.main_table>
```

### Context Module

```elixir
defmodule MyApp.Accounts do
  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Accounts.User

  def list_users(params) do
    User
    |> ExLiveTable.handle_search(params)
    |> ExLiveTable.handle_sorting(params)
    |> Repo.paginate(params)
  end
  
  def list_all_users(params) do
    User
    |> ExLiveTable.handle_search(params)
    |> ExLiveTable.handle_sorting(params)
    |> Repo.all()
  end
end
```

## Advanced Options

### Customizing Row Click Behavior

```heex
<ExLiveTable.main_table 
  id="users" 
  rows={@users} 
  params={@params}
  row_click={fn user -> JS.navigate(~p"/users/#{user}") end}>
  <!-- columns -->
</ExLiveTable.main_table>
```

### Dynamic Row ID and Item Transformation

```heex
<ExLiveTable.main_table 
  id="users" 
  rows={@users} 
  params={@params}
  row_id={fn user -> "user-#{user.id}" end}
  row_item={fn user -> Map.put(user, :full_name, "#{user.first_name} #{user.last_name}") end}>
  <:col :let={user} label="Full Name"><%= user.full_name %></:col>
  <!-- more columns -->
</ExLiveTable.main_table>
```

### Loading State

```heex
<ExLiveTable.main_table 
  id="users" 
  rows={@users} 
  params={@params}
  data_loader={@loading}>
  <!-- columns -->
</ExLiveTable.main_table>
```

## Styling Options

The ExLiveTable comes with a default styling system based on Tailwind CSS. You can customize the appearance by:

1. Adding custom CSS classes to columns
2. Overriding the default styles in your app.css

Example of custom column classes:

```heex
<ExLiveTable.main_table id="users" rows={@users} params={@params}>
  <:col :let={user} label="ID" class="font-mono"><%= user.id %></:col>
  <:col :let={user} label="Status" label_class="text-center" class="text-center">
    <span class={"badge #{status_color(user.status)}"}>
      <%= user.status %>
    </span>
  </:col>
  <!-- more columns -->
</ExLiveTable.main_table>
```

## Handling Pagination with Scrivener

Make sure to add Scrivener to your dependencies:

```elixir
defp deps do
  [
    {:scrivener_ecto, "~> 2.7"}
  ]
end
```

Configure Scrivener in your repo:

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
```

Use Scrivener in your context:

```elixir
def list_users(params) do
  page = params["page"] || "1"
  page_size = params["page_size"] || "10"

  params = Map.merge(params, %{
    "page" => page,
    "page_size" => page_size
  })

  User
  |> ExLiveTable.handle_search(params)
  |> ExLiveTable.handle_sorting(params)
  |> Repo.paginate(params)
end
```

## Export Functionality

To implement the export functionality, you'll need additional libraries depending on the export format:

- For CSV: `{:csv, "~> 2.4"}`
- For Excel: `{:xlsx_creator, "~> 0.4.2"}`
- For PDF: `{:pdf_generator, "~> 0.6.2"}`

Example implementation:

```elixir
def generate_csv(users) do
  csv_content =
    [["ID", "Name", "Email", "Role", "Created At"]] ++
    Enum.map(users, fn user ->
      [
        user.id,
        user.name,
        user.email,
        user.role,
        Calendar.strftime(user.inserted_at, "%Y-%m-%d")
      ]
    end)
    |> CSV.encode()
    |> Enum.to_list()
    |> Enum.join()

  # Return the CSV for download
  %{
    content: csv_content,
    content_type: "text/csv",
    filename: "users_export.csv"
  }
end
```

## Custom Search Implementation

For more advanced search needs, you can override the default search behavior:

```elixir
def list_users(params) do
  search_term = get_in(params, ["filter", "isearch"]) || ""
  
  query = from u in User
  
  query =
    if search_term != "" do
      search_term = "%#{search_term}%"
      from u in query,
        where:
          ilike(u.name, ^search_term) or
          ilike(u.email, ^search_term) or
          ilike(u.role, ^search_term)
    else
      query
    end
    
  query
  |> ExLiveTable.handle_sorting(params)
  |> Repo.paginate(params)
end
```

## Performance Considerations

For large datasets:

1. Ensure proper database indexing on sorted and filtered columns
2. Consider using limit/offset instead of fetching all records
3. Use `row_item` for complex transformations to avoid doing them in the template

## Troubleshooting

Common issues:

1. **Pagination not working**: Ensure you're using Scrivener correctly and passing the `params` to the table component
2. **Sorting not affecting results**: Check that the field names match your database columns
3. **Search not working**: Verify that the `iSearch` event is properly handled and the filter parameters are correctly passed