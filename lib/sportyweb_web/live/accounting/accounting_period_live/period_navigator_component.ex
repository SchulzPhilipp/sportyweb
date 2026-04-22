defmodule SportywebWeb.PeriodNavigatorComponent do
  use SportywebWeb, :html

  # this component handles the switching of bookingperiods as an element of the UI
  def period_navigator(assigns) do
    ~H"""
    <div class="flex items-center justify-center gap-2 text-lg">
    <%= if @period_index > 0 do %>
      <% prev_period = Enum.at(@all_periods, @period_index - 1) %>
        <.link
          href={~p"/clubs/#{@club.id}/periods/#{prev_period.id}/activate"}
          class="p-1 rounded hover:bg-zinc-100"
        >
          <.icon name="hero-chevron-left" class="h-6 w-6 text-zinc-500" />
        </.link>
      <% else %>
        <span class="p-1 opacity-30">
          <.icon name="hero-chevron-left" class="h-6 w-6 text-zinc-300" />
        </span>
      <% end %>

      <span class="font-semibold text-zinc-800 text-lg min-w-[200px] text-center flex justify-center">
        <%= if @active_period do %>
          <%= @active_period.name %>
        <% else %>
              <.link navigate={~p"/clubs/#{@club}/accounting_periods/new"}>
                <.button> Buchungsperiode erstellen</.button>
              </.link>
        <% end %>
      </span>

    <%= if @period_index < length(@all_periods) - 1 do %>
      <% next_period = Enum.at(@all_periods, @period_index + 1) %>
        <.link
          href={~p"/clubs/#{@club.id}/periods/#{next_period.id}/activate"}
          class="p-1 rounded hover:bg-zinc-100"
        >
          <.icon name="hero-chevron-right" class="h-6 w-6 text-zinc-500" />
        </.link>
      <% else %>
        <span class="p-1 opacity-30">
          <.icon name="hero-chevron-right" class="h-6 w-6 text-zinc-300" />
        </span>
      <% end %>
    </div>
    """
  end
end
