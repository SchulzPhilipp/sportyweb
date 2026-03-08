defmodule SportywebWeb.AccountLive.FormComponent do
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
        id="account-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

          <.input_grids>
            <.input_grid>
              <div class="col-span-12 md:col-span-4">
                <.input field={@form[:accountnumber]} type="text" label="Kontonummer" />
              </div>

              <div class="col-span-12 md:col-span-4">
                <.input field={@form[:accountname]} type="text" label="Kontoname" />
              </div>

              <div class="col-span-12 md:col-span-4">
                <.input field={@form[:accountbalance]} type="text" label="Saldo" step="any" />
              </div>

              <div class="col-span-12 md:col-span-4">
                <.input
                  field={@form[:accountclass_id]}
                  type="select"
                  label="Kontenklasse"
                  options={@accountclasses_options}
                  prompt="Bitte wählen..."
                />
              </div>

              <div class="col-span-12 md:col-span-4">
                <.input
                  field={@form[:accountgroup_id]}
                  type="select"
                  label="Kontengruppe"
                  options={@accountgroups_options}
                  prompt="Bitte wählen..."
                />
              </div>

              <div class="col-span-12 md:col-span-4">
                <.input
                  field={@form[:accounttypecode]}
                  type="select"
                  label="Kontotyp"
                  options={Sportyweb.Accounting.Account.accounttypecode_options()}
                  prompt="Bitte wählen..."
                />
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
              :if={@account.id}
              class="bg-rose-700 hover:bg-rose-800"
              phx-click={JS.push("delete", value: %{id: @account.id})}
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
def update(%{account: account} = assigns, socket) do
  changeset = Accounting.change_account(account)
  club_id = assigns[:club_id] || (assigns[:account] && assigns[:account].club_id)

  # socket =
  #   if club_id do
  #     assign_options(socket, club_id)
  #   else
  #     socket
  #   end


  {:ok,
   socket
   |> assign(assigns)
   |> assign(:club_id, club_id)
   |> assign_options(club_id)
   |> assign_new(:form, fn -> to_form(changeset) end)}
end


# Hilfsfunktion
defp assign_options(socket, club_id) do
  socket
  |> assign(:accountclasses_options,
      Accounting.list_accountclasses(club_id)
      |> Enum.map(&{&1.accountclassname, &1.id}))
  |> assign(:accountgroups_options,
      Accounting.list_accountgroups(club_id)
      |> Enum.map(&{&1.accountgroupname, &1.id}))
end


  @impl true
  def handle_event("validate", %{"account" => account_params}, socket) do
    changeset =
      Accounting.change_account(socket.assigns.account, account_params)

    changeset
    |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"account" => account_params}, socket) do
    save_account(socket, socket.assigns.action, account_params)
  end

  defp save_account(socket, :edit, account_params) do
    case Accounting.update_account(socket.assigns.account, account_params) do
      {:ok, account} ->
        account = Sportyweb.Repo.preload(account, [:club, :accountclass, :accountgroup])
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Konto erfolgreich aktualisiert")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_account(socket, :new, account_params) do
    account_params = Enum.into(account_params, %{"club_id" => socket.assigns.club_id})
    #IO.inspect(account_params)
    case Accounting.create_account(account_params) do
      {:ok, account} ->
        account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup])

        {:noreply,
         socket
         |> put_flash(:info, "Konto erfolgreich erstellt")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
