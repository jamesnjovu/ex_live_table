defmodule ExLiveTable.MainTable do
  @moduledoc """
  Renders a responsive data table with sorting, filtering, and pagination.

  This component provides both desktop and mobile views, built-in search,
  and export functionality.
  """
  use Phoenix.Component
  import Phoenix.LiveView.Helpers
  import ExLiveTable.DataTable
  alias ExLiveTable.PaginationComponent
  alias Phoenix.LiveView.JS

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <ExLiveTable.main_table id="users" rows={@users} params={@params}>
        <:col :let={user} label="ID"><%= user.id %></:col>
        <:col :let={user} label="Username"><%= user.username %></:col>
        <:action :let={user}>
          <button phx-click="edit" phx-value-id={user.id}>Edit</button>
        </:action>
      </ExLiveTable.main_table>
  """
  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:extraction, :boolean, default: true)
  attr(:params, :map, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:data_loader, :boolean, default: false, doc: "indicates if data is currently loading")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string)
    attr(:label_class, :string)
    attr(:class, :string)
  end

  slot(:action, doc: "the slot for showing user actions in the last table column")

  def main_table(assigns) do
    ~H"""
    <div class="w-full">
      <div class="flex justify-between items-center w-full gap-10 flex-wrap px-4 sm:px-0">
        <div
          class="sm:flex-auto"
          phx-mounted={
            JS.transition(
              {"transition ease-ease-in-out duration-300 transform", "-translate-x-full opacity-0",
               "translate-x-0 opacity-100"}
            )
          }
        >
          <.isearch params={@params} />
        </div>

        <div
          :if={@extraction}
          show
          class="flex justify-end items-center gap-2"
          phx-mounted={
            JS.transition(
              {"transition ease-ease-in-out duration-300 transform", "translate-x-full opacity-0",
               "translate-x-0 opacity-100"}
            )
          }
        >
          <button class="export-button p-2" onclick="history.back()" title="Back">
            <i class="hero-arrow-left w-5 h-5"></i>
          </button>

          <button class="export-button p-2" phx-click="filter" title="Filter">
            <i class="hero-funnel w-5 h-5"></i>
          </button>

          <%= if @data_loader do %>
            <button class="btn btn-primary">
              <svg
                class="size-6 animate-spin"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                stroke="currentColor"
                stroke-width="1"
                stroke-linecap="round"
                stroke-linejoin="round"
                viewBox="0 0 24 24"
              >
                <polyline points="1 4 1 10 7 10"></polyline>

                <polyline points="23 20 23 14 17 14"></polyline>

                <path d="M20.49 9A9 9 0 0 0 6.6 4.11L1 10M23 14l-5.59 5.89A9 9 0 0 1 3.51 15"></path>
              </svg>
            </button>
          <% else %>
            <button
              class="export-button btn btn-primary"
              phx-click="refresh_table"
              title="Refresh Table"
            >
              <svg
                class="size-6"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                stroke="currentColor"
                stroke-width="1"
                stroke-linecap="round"
                stroke-linejoin="round"
                viewBox="0 0 24 24"
              >
                <path d="M17.59 3.41a9 9 0 1 1-11.18 0M12 7v5h5"></path>
              </svg>
            </button>
          <% end %>

          <button class="export-button" phx-click="export" phx-value-file_type="csv">
            CSV
          </button>

          <button class="export-button" phx-click="export" phx-value-file_type="xlsx">
            Excel
          </button>

          <button class="export-button" phx-click="export" phx-value-file_type="pdf">
            PDF
          </button>
        </div>
      </div>
    </div>
    <!-- Desktop Table View -->
    <div class="hidden md:block mt-4">
      <div
        class="w-full mt-2 transition-transform rounded-none border bg-white shadow-sm shadow ring- ring-black ring-opacity-5 sm:rounded-lg"
        phx-mounted={
          JS.transition(
            {"transition ease-in-out duration-300 transform", "-translate-y-full opacity-0",
             "translate-y-0"}
          )
        }
      >
        <table class="min-w-full divide-y divide-gray-300">
          <thead class="bg-brand-10 ring-x ring-t ring-x-brand-1 ring-t-brand-1 sticky top-0">
            <tr>
              <th
                :for={col <- @col}
                class={"px-1 border-b-2 border-brand-10 py-3 border-b-brand-700 #{col[:label_class]} text-left text-sm text-white font-semibold text-gray-900"}
              >
                <%= col[:label] %>
              </th>

              <th
                :if={@action != []}
                class="relative border-b-2 border-brand-10 py-3.5 pl-3 pr-4 sm:pr-6"
              >
                <span class="sr-only">Actions</span>
              </th>
            </tr>
          </thead>

          <tbody id={"#{@id}-tbody"} class="divide-y divide-gray-200 bg-white">
            <tr
              :for={{row, rowi} <- Enum.with_index(@rows)}
              id={@row_id && @row_id.(row)}
              class={[
                "animate-slide-in-from-top transition-transform duration-300 border-b transition duration-300 ease-in-out hover:bg-neutral-100",
                :math.fmod(rowi, 2) == 0.0 && "bg-neutral-50"
              ]}
            >
              <td
                :for={{col, _i} <- Enum.with_index(@col)}
                phx-click={@row_click && @row_click.(row)}
                class={[
                  "whitespace-nowrap px-3 py-4 text-sm text-gray-500 #{col[:class]}",
                  @row_click && "hover:cursor-pointer"
                ]}
              >
                <%= render_slot(col, @row_item.(row)) %>
              </td>

              <td
                :if={@action != []}
                class="relative whitespace-nowrap py-2 pl-3 pr-4 text-right text-sm font-medium sm:pr-6"
              >
                <%= render_slot(@action, @row_item.(row)) %>
              </td>
            </tr>
            <.empty_table data_loader={@data_loader} data={@rows} />
          </tbody>
        </table>
      </div>

      <div class="w-full">
        <.live_component
          module={PaginationComponent}
          id="PaginationComponentT4"
          params={@params}
          pagination_data={@rows}
        />
      </div>
    </div>
    <!-- Mobile Table View -->
    <div class="block md:hidden mt-4">
      <div
        class="space-y-4 px-4"
        phx-mounted={
          JS.transition(
            {"ease-in duration-300", "-translate-y-full opacity-0", "translate-y-0 opacity-100"}
          )
        }
      >
        <div
          :for={{row, index} <- Enum.with_index(@rows)}
          class={[
            "bg-white rounded-lg border shadow-sm",
            @row_click && "cursor-pointer hover:bg-gray-50",
            rem(index, 2) == 0 && "bg-gray-50/50"
          ]}
          id={@row_id && @row_id.(row)}
          phx-click={@row_click && @row_click.(row)}
        >
          <div class="p-4 space-y-3">
            <div
              :for={{col, _i} <- Enum.with_index(@col)}
              class="flex justify-between items-center gap-4 border-b border-gray-100 last:border-0 pb-2 last:pb-0"
            >
              <span class="text-sm font-medium text-gray-500">
                <%= col[:label] %>
              </span>

              <span class="text-sm text-gray-900 text-right">
                <%= render_slot(col, @row_item.(row)) %>
              </span>
            </div>

            <div :if={@action != []} class="pt-2 flex justify-end">
              <%= render_slot(@action, @row_item.(row)) %>
            </div>
          </div>
        </div>
      </div>

      <div class="w-full">
        <.live_component
          module={PaginationComponent}
          id="PaginationComponentT3"
          params={@params}
          pagination_data={@rows}
        />
      </div>
    </div>
    """
  end
end
