defmodule SportywebWeb.AccounttypeLive.FormComponent do
  use SportywebWeb, :live_component

  alias Sportyweb.Accounting

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage accounttype records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="accounttype-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:accounttypename]} type="text" label="Accounttypename" />
        <.input field={@form[:accounttypecode]} type="text" label="Accounttypecode" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Accounttype</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{accounttype: accounttype} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounting.change_accounttype(accounttype))
     end)}
  end

  @impl true
  def handle_event("validate", %{"accounttype" => accounttype_params}, socket) do
    changeset = Accounting.change_accounttype(socket.assigns.accounttype, accounttype_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"accounttype" => accounttype_params}, socket) do
    save_accounttype(socket, socket.assigns.action, accounttype_params)
  end

  defp save_accounttype(socket, :edit, accounttype_params) do
    case Accounting.update_accounttype(socket.assigns.accounttype, accounttype_params) do
      {:ok, accounttype} ->
        notify_parent({:saved, accounttype})

        {:noreply,
         socket
         |> put_flash(:info, "Accounttype updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_accounttype(socket, :new, accounttype_params) do
    case Accounting.create_accounttype(accounttype_params) do
      {:ok, accounttype} ->
        notify_parent({:saved, accounttype})

        {:noreply,
         socket
         |> put_flash(:info, "Accounttype created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
