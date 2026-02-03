defmodule SportywebWeb.AccountgroupLive.FormComponent do
  use SportywebWeb, :live_component

  alias Sportyweb.Accounting

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage accountgroup records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="accountgroup-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:accountgroupnumber]} type="text" label="Accountgroupnumber" />
        <.input field={@form[:accountgroupname]} type="text" label="Accountgroupname" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Accountgroup</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{accountgroup: accountgroup} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
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
         |> put_flash(:info, "Accountgroup updated successfully")
         |> push_patch(to: socket.assigns.patch)}

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
         |> put_flash(:info, "Accountgroup created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
