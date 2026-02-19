defmodule SportywebWeb.AccountLive.FormComponent do
  use SportywebWeb, :live_component

  alias Sportyweb.Accounting

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage account records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="account-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:accountnumber]} type="text" label="Accountnumber" />
        <.input field={@form[:accountname]} type="text" label="Accountname" />
        <.input field={@form[:accountbalance]} type="text" label="Accountbalance" step="any" />
        <.input
          field={@form[:accountclass_id]}
          type="select"
          label="Accountclass"
          options={@accountclasses_options}
          prompt="Bitte wählen..."
        />
        <.input
          field={@form[:accountgroup_id]}
          type="select"
          label="Accountgroup"
          options={@accountgroups_options}
          prompt="Bitte wählen..."
        />
        <.input
          field={@form[:accounttype_id]}
          type="select"
          label="Accounttype"
          options={@accounttypes_options}
          prompt="Bitte wählen..."
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{account: account} = assigns, socket) do
    # Lade die Auswahlmöglichkeiten für die Accountclasses, Accountgroups und Accounttypes
    accountclasses_options =
      Sportyweb.Accounting.list_accountclasses()
      # Format für das Select: {"Anzeigename"}
      |> Enum.map(&{&1.accountclassname, &1.id})

    accountgroups_options =
      Sportyweb.Accounting.list_accountgroups()
      # Format für das Select: {"Anzeigename"}
      |> Enum.map(&{&1.accountgroupname, &1.id})

    accounttypes_options =
      Sportyweb.Accounting.list_accounttypes()
      # Format für das Select: {"Anzeigename"}
      |> Enum.map(&{&1.accounttypename, &1.id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:accountclasses_options, accountclasses_options)
     |> assign(:accountgroups_options, accountgroups_options)
     |> assign(:accounttypes_options, accounttypes_options)
     |> assign_new(:form, fn ->
       to_form(Accounting.change_account(account))
     end)}
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
        account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Account updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_account(socket, :new, account_params) do
    case Accounting.create_account(account_params) do
      {:ok, account} ->
        account = Sportyweb.Repo.preload(account, [:accountclass, :accountgroup, :accounttype])
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
