defmodule SportywebWeb.AccountclassLive.FormComponent do
  use SportywebWeb, :live_component

  alias Sportyweb.Accounting

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage accountclass records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="accountclass-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:accountclassnumber]} type="text" label="Accountclassnumber" />
        <.input field={@form[:accountclassname]} type="text" label="Accountclassname" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Accountclass</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{accountclass: accountclass} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
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
         |> put_flash(:info, "Accountclass updated successfully")
         |> push_patch(to: socket.assigns.patch)}

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
         |> put_flash(:info, "Accountclass created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
