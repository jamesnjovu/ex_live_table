defmodule ExLiveTable.PaginationComponent do
  @moduledoc """
  LiveComponent for handling pagination in tables.

  This component displays pagination controls for navigating between pages of results.
  It supports both desktop and mobile views.
  """
  use Phoenix.LiveComponent
  import Phoenix.HTML.Link
  import Phoenix.Component
  import ExLiveTable.DataTable, only: [querystring: 2]

  @distance 5

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(pagination_assigns(assigns[:pagination_data]))

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="rounded-b-md flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6">
      <div class="flex flex-1 justify-between items-center sm:hidden">
        <%= if @page_number != 1 do %>
          <.link
            patch={"?#{querystring(@params, page: @page_number - 1)}"}
            class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            Previous
          </.link>
        <% else %>
          <button disabled class="relative inline-flex items-center rounded-md border border-gray-300 bg-gray-100 px-4 py-2 text-sm font-medium text-gray-500 cursor-not-allowed">
            Previous
          </button>
        <% end %>

        <div class="flex flex-col items-center mx-2">
          <span class="text-sm font-semibold text-gray-900">
            Page <%= @page_number %>
          </span>
          <span class="text-xs text-gray-500">
            of <%= @total_pages %>
          </span>
        </div>

        <%= if @page_number != @total_pages and @total_pages > 0 do %>
          <.link
            patch={"?#{querystring(@params, page: @page_number + 1)}"}
            class="relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            Next
          </.link>
        <% else %>
          <button disabled class="relative inline-flex items-center rounded-md border border-gray-300 bg-gray-100 px-4 py-2 text-sm font-medium text-gray-500 cursor-not-allowed">
            Next
          </button>
        <% end %>
      </div>

      <div class="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-gray-700">
            Showing
            <span class="font-medium">
              <%= if @total_entries != 0, do: (@page_number - 1) * @page_size + 1, else: 0 %>
            </span>
            to
            <span class="font-medium">
              <%= if @page_number * @page_size > @total_entries,
                do: @total_entries,
                else: @page_number * @page_size %>
            </span>
            of <span class="font-medium"><%= @total_entries %></span>
            results
          </p>
        </div>
        <div>
          <nav
            id={assigns[:id] || "pagination"}
            class="isolate inline-flex -space-x-px rounded-md shadow-sm"
            aria-label="Pagination"
            role="navigation"
          >
            <%= if @total_pages > 1 do %>
              <%= if @page_number != 1 do %>
                <.link
                  patch={"?#{querystring(@params, page: @page_number - 1)}"}
                  class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
                  aria-label="Previous page"
                >
                  <span class="sr-only">Previous</span>
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </.link>
              <% end %>

              <%= for num <- start_page(@page_number)..end_page(@page_number, @total_pages) do %>
                <%= if @page_number == num do %>
                  <.link
                    patch={"?#{querystring(@params, page: num)}"}
                    aria-current="page"
                    class="relative z-10 inline-flex items-center bg-brand-1 px-4 py-2 text-sm font-semibold text-white focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                    aria-label={"Page #{num}, current page"}
                  >
                    <%= num %>
                  </.link>
                <% else %>
                  <.link
                    patch={"?#{querystring(@params, page: num)}"}
                    class="relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
                    aria-label={"Go to page #{num}"}
                  >
                    <%= num %>
                  </.link>
                <% end %>
              <% end %>

              <%= if @page_number != @total_pages do %>
                <.link
                  patch={"?#{querystring(@params, page: @page_number + 1)}"}
                  class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0"
                  aria-label="Next page"
                >
                  <span class="sr-only">Next</span>
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </.link>
              <% end %>
            <% end %>
          </nav>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Extracts pagination attributes from data.
  Handles both Scrivener.Page structs and empty lists.
  """
  defp pagination_assigns([]) do
    [
      page_number: 1,
      page_size: 10,
      total_entries: 0,
      total_pages: 0
    ]
  end

  defp pagination_assigns(%Scrivener.Page{} = pagination) do
    [
      page_number: pagination.page_number,
      page_size: pagination.page_size,
      total_entries: pagination.total_entries,
      total_pages: pagination.total_pages
    ]
  end

  @doc """
  Calculates the starting page number for pagination display.
  """
  def start_page(current_page) when current_page - @distance <= 0, do: 1
  def start_page(current_page), do: current_page - @distance

  @doc """
  Calculates the ending page number for pagination display.
  """
  def end_page(current_page, 0), do: current_page

  def end_page(current_page, total)
      when current_page <= @distance and @distance * 2 <= total do
    @distance * 2
  end

  def end_page(current_page, total) when current_page + @distance >= total, do: total
  def end_page(current_page, _total), do: current_page + @distance - 1
end
