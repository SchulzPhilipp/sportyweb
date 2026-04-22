defmodule SportywebWeb.Accounting.AccountclassLive.FormComponent do
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
          id="accountclass-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
        <.input_grids>
          <.input_grid>
            <div class="col-span-12 md:col-span-4">
              <.input field={@form[:accountclassnumber]} type="text" label="Nummer" />
            </div>
            <div class="col-span-12 md:col-span-8">
              <.input field={@form[:accountclassname]} type="text" label="Bezeichnung" />
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
              :if={@accountclass.id}
              class="bg-rose-700 hover:bg-rose-800"
              phx-click={JS.push("delete", value: %{id: @accountclass.id})}
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
  def update(%{accountclass: accountclass} = assigns, socket) do
    club_id = assigns[:club_id] || (assigns[:accountclass] && assigns[:accountclass].club_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:club_id, club_id)
     |> assign_new(:form, fn ->
       to_form(Accounting.change_accountclass(accountclass))
     end)}
  end

  @impl true
  def handle_event("validate", %{"accountclass" => accountclass_params}, socket) do
    changeset = Accounting.change_accountclass(socket.assigns.accountclass, accountclass_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"accountclass" => accountclass_params}, socket) do
    save_accountclass(socket, socket.assigns.action, accountclass_params)
  end

  defp save_accountclass(socket, :edit, accountclass_params) do
    case Accounting.update_accountclass(socket.assigns.accountclass, accountclass_params) do
      {:ok, accountclass} ->
        notify_parent({:saved, accountclass})

        {:noreply,
         socket
         |> put_flash(:info, "Kontenklasse erfolgreich aktualisiert")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_accountclass(socket, :new, accountclass_params) do
    case Accounting.create_accountclass(accountclass_params) do
      {:ok, accountclass} ->
        notify_parent({:saved, accountclass})

        {:noreply,
         socket
         |> put_flash(:info, "Kontenklasse erfolgreich erstellt")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
