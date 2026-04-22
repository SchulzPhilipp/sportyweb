defmodule SportywebWeb.Accounting.AccountingPeriodLive.FormComponent do
  use SportywebWeb, :live_component

  alias Sportyweb.Accounting


  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.card>
        <.simple_form
          for={@form}
          id="accounting_period-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input_grids>
            <.input_grid>
              <div class="col-span-12 md:col-span-8">
                <.input field={@form[:name]} type="text" label="Wirtschaftsjahr" />
              </div>
              <div class="col-span-12 md:col-span-4">
                <.input
                  field={@form[:status]}
                  type="select"
                  label="Status"
                  options={Sportyweb.Accounting.AccountingPeriod.status_options()}
                  prompt="Bitte wählen..."
                />
              </div>
              <div class="col-span-12 md:col-span-4">
                <.input field={@form[:starts_on]} type="date" label="Beginn" />
              </div>
              <div class="col-span-12 md:col-span-4">
                <.input field={@form[:ends_on]} type="date" label="Ende" />
              </div>
              <input type="hidden" name={@form[:club_id].name} value={@club_id} />
            </.input_grid>
          </.input_grids>
          <:actions>
            <div>
              <.button phx-disable-with="Speichern...">Speichern</.button>
              <.cancel_button navigate={@navigate}>Abbrechen</.cancel_button>
            </div>
            <.button
              :if={@accounting_period.id}
              class="bg-rose-700 hover:bg-rose-800"
              phx-click={JS.push("delete", value: %{id: @accounting_period.id})}
              data-confirm="Unwiderruflich löschen?"
            >
              Löschen
            </.button>
          </:actions>
        </.simple_form>
      </.card>
    </div>
    """
  end

  @impl true
  def update(%{accounting_period: accounting_period} = assigns, socket) do
    club_id = assigns[:club_id] || (assigns[:accounting_period] && assigns[:accounting_period].club_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:club_id, club_id)
     |> assign_new(:form, fn ->
       to_form(Accounting.change_accounting_period(accounting_period))
     end)}
  end

  @impl true
  def handle_event("validate", %{"accounting_period" => accounting_period_params}, socket) do
    changeset = Accounting.change_accounting_period(socket.assigns.accounting_period, accounting_period_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"accounting_period" => accounting_period_params}, socket) do
    save_accounting_period(socket, socket.assigns.action, accounting_period_params)
  end

  defp save_accounting_period(socket, :edit, accounting_period_params) do
    case Accounting.update_accounting_period(socket.assigns.accounting_period, accounting_period_params) do
      {:ok, accounting_period} ->
        notify_parent({:saved, accounting_period})

        {:noreply,
         socket
         |> put_flash(:info, "Buchungsperiode erfolgreich aktualisiert")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_accounting_period(socket, :new, accounting_period_params) do
    case Accounting.create_accounting_period(accounting_period_params) do
      {:ok, accounting_period} ->
        notify_parent({:saved, accounting_period})

        {:noreply,
         socket
         |> put_flash(:info, "Buchungsperiode erfolgreich erstellt")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
