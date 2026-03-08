defmodule SportywebWeb.AccountgroupLive.FormComponent do
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
          id="accountgroup-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
        <.input_grids>
          <.input_grid>
            <div class="col-span-12 md:col-span-12">
              <.input field={@form[:accountgroupname]} type="text" label="Bezeichnung" />
            </div>
            <.input field={@form[:club_id]} type="hidden" value={@club_id} />
          </.input_grid>
        </.input_grids>
          <:actions>
            <div>
              <.button phx-disable-with="Speichern...">Speichern</.button>
              <.cancel_button navigate={@navigate}>Abbrechen</.cancel_button>
            </div>
            <.button
              :if={@accountgroup.id}
              class="bg-rose-700 hover:bg-rose-800"
              phx-click={JS.push("delete", value: %{id: @accountgroup.id})}
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
  def update(%{accountgroup: accountgroup} = assigns, socket) do
    club_id = assigns[:club_id] || (assigns[:accountgroup] && assigns[:accountgroup].club_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:club_id, club_id)
     |> assign_new(:form, fn ->
       to_form(Accounting.change_accountgroup(accountgroup))
     end)}
  end

  @impl true
  def handle_event("validate", %{"accountgroup" => accountgroup_params}, socket) do
    changeset = Accounting.change_accountgroup(socket.assigns.accountgroup, accountgroup_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"accountgroup" => accountgroup_params}, socket) do
    save_accountgroup(socket, socket.assigns.action, accountgroup_params)
  end

  defp save_accountgroup(socket, :edit, accountgroup_params) do
    case Accounting.update_accountgroup(socket.assigns.accountgroup, accountgroup_params) do
      {:ok, accountgroup} ->
        notify_parent({:saved, accountgroup})

        {:noreply,
         socket
         |> put_flash(:info, "Kontengruppe erfolgreich aktualisiert")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_accountgroup(socket, :new, accountgroup_params) do
    case Accounting.create_accountgroup(accountgroup_params) do
      {:ok, accountgroup} ->
        notify_parent({:saved, accountgroup})

        {:noreply,
         socket
         |> put_flash(:info, "Kontengruppe erfolgreich erstellt")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
