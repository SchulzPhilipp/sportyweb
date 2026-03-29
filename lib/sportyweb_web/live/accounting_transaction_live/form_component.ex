defmodule SportywebWeb.AccountingTransactionLive.FormComponent do
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
          id="accounting_transaction-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
        <fieldset disabled={@deleted? || @pending? || @posted? || @voided?} class={if (@deleted? || @pending? || @posted? || @voided?), do: "opacity-60 cursor-not-allowed"}>
        <.input_grids>
          <.input_grid>

            <div class="col-span-12 md:col-span-6">
              <.input
                field={@form[:description]}
                type="text"
                label="Beschreibung" />
            </div>
            <div class="col-span-12 md:col-span-6">
              <.input
                field={@form[:reference]}
                type="text"
                label="Referenz" />
            </div>
            <div class="col-span-12 md:col-span-6">
              <.input
                field={@form[:status]}
                type="select"
                label="Status"
                options={status_options(@accounting_transaction.status)} />
            </div>
            <div class="col-span-12 md:col-span-6">
              <.input
                field={@form[:sphere]}
                type="select"
                label="Sphäre"
                options={sphere_options()} />
            </div>
            <input type="hidden" name={@form[:club_id].name} value={@club_id} />

          </.input_grid>
        </.input_grids>
        </fieldset>

        <%!-- Buchungszeilen --%>
        <br/>
        <.card>
        <fieldset disabled={@deleted? || @pending? || @posted? || @voided?} class={if (@deleted? || @pending? || @posted? || @voided?), do: "opacity-60 cursor-not-allowed"}>
          <.inputs_for :let={entry_form} field={@form[:entries]}>
            <input type="hidden" name={@form[:club_id].name} value={@club_id} />
            <.input_grid>
              <div class="col-span-12 md:col-span-5">
                    <label :if={entry_form.index == 0} class="block text-sm font-semibold leading-6 text-zinc-800">Konto</label>

                    <%!-- Verstecktes Feld für die tatsächliche account_id --%>
                    <input type="hidden" name={entry_form[:account_id].name} value={entry_form[:account_id].value || ""} />

                    <%!-- Suchfeld --%>
                    <input
                      type="text"
                      value={Map.get(@account_search, "#{entry_form.index}", get_account_name(@accounts, entry_form[:account_id].value))}
                      placeholder="Kontobezeichnung suchen..."
                      phx-target={@myself}
                      phx-keyup="search_account"
                      phx-value-index={entry_form.index}
                      class="mt-2 py-2.5 block w-full rounded-md border border-zinc-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
                      autocomplete="off" />

                    <%!-- Dropdown-Ergebnisse --%>
                    <%= if length(Map.get(@account_results, "#{entry_form.index}", [])) > 0 do %>
                      <div class="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-y-auto">
                        <%= for {name, id} <- Map.get(@account_results, "#{entry_form.index}", []) do %>
                          <div
                            class="px-3 py-2 text-sm cursor-pointer hover:bg-blue-50"
                            phx-click="select_account"
                            phx-target={@myself}
                            phx-value-index={entry_form.index}
                            phx-value-id={id}
                            phx-value-name={name}>
                            {name}
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                    <%!-- Fehler manuell unterhalb anzeigen --%>
                    <%= for msg <- Enum.map(entry_form[:account_id].errors, &SportywebWeb.CoreComponents.translate_error(&1)) do %>
                      <p class="mt-2 flex gap-3 text-sm leading-6 text-rose-600">
                        <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
                        {msg}
                      </p>
                    <% end %>
                  </div>
                  <div class="col-span-12 md:col-span-3">
                    <div :if={entry_form.index == 0} class="relative flex items-center gap-1 h-6 mb-0">
                      <.label :if={entry_form.index == 0} for={entry_form[:amount_input].id}>Betrag in EUR</.label>
                      <div :if={entry_form.index == 0} class="group relative mb-1">
                        <.icon name="hero-information-circle" class="h-4 w-4 text-zinc-400 cursor-help" />
                        <div class="hidden group-hover:block absolute z-20 left-0 top-6 w-64 bg-zinc-800 text-white text-xs rounded-md p-2 leading-5">
                          Positiver Betrag = Soll (Debit)<br :if={entry_form.index == 0}/>
                          Negativer Betrag = Haben (Kredit)
                        </div>
                      </div>
                      <div :if={entry_form.index > 0} class="h-6" />
                    </div>
                    <.input
                      field={entry_form[:amount_input]}
                      type="number"
                      step="any" />
                  </div>
              <div class="col-span-12 md:col-span-3">
                <.input
                  field={entry_form[:description]}
                  type="text"
                  label={if entry_form.index == 0, do: "Beschreibung", else: ""}/>
              </div>
              <div class="col-span-12 md:col-span-1 flex items-end">
                <.button
                  :if={!@deleted? && !@pending? && !@posted? && !@voided?}
                  type="button"
                  class="bg-rose-700 hover:bg-rose-800"
                  phx-target={@myself}
                  phx-click="remove_entry"
                  phx-value-index={entry_form.index}>
                  –
                </.button>
              </div>
            </.input_grid>
          </.inputs_for>

          <%!-- Summenanzeige --%>
          <div class="mt-4 text-right font-semibold">
            <% sum = calculate_sum(@form) %>
            <% balanced? = Money.zero?(sum) %>
            <%= if balanced? do %>
              <span class="text-green-600">Summe: {display_money(sum)} ✓ ausgeglichen</span>
            <% else %>
              <span class="text-red-600">Summe: {display_money(sum)} ✗ nicht ausgeglichen</span>
            <% end %>
          </div>
          </fieldset>
          <.button
            :if={!@deleted? && !@pending? && !@posted? && !@voided?}
            type="button"
            phx-target={@myself}
            phx-click="add_entry"
            class="mt-4">
            + Buchungszeile hinzufügen
          </.button>
        </.card>
          <:actions>
            <div>
              <.button :if={!@deleted? && !@pending? && !@posted? && !@voided?} phx-disable-with="Speichern...">Speichern</.button>
              <.cancel_button :if={!@deleted? && !@pending? && !@posted? && !@voided?} navigate={@navigate}>Abbrechen</.cancel_button>
            </div>
            <.button
              :if={@accounting_transaction.id && (!@deleted? && !@pending? && !@posted? && !@voided?)}
              class="bg-rose-700 hover:bg-rose-800"
              phx-click={JS.push("delete", value: %{id: @accounting_transaction.id})}
              data-confirm="Unwiderruflich löschen?"
            >
              Löschen
            </.button>
            <.button
              :if={@posted? && !@voided? && !@deleted?}
              class="bg-rose-700 hover:bg-rose-800"
              phx-click="void"
              data-confirm="Buchung unwiderruflich stornieren?">
              Stornieren
            </.button>
          </:actions>
        </.simple_form>
      </.card>
      <.back navigate={~p"/clubs/#{@accounting_transaction.club_id}/journal"}>
        Zurück zum Journal
      </.back>
    </div>
    """
  end

  @impl true
  def update(%{accounting_transaction: accounting_transaction} = assigns, socket) do
    changeset = Accounting.change_accounting_transaction(accounting_transaction)
    club_id = assigns[:club_id] || assigns.accounting_transaction.club_id

    accounts = Accounting.list_accounts(club_id)
      |> Enum.map(fn account -> {account.accountname, account.id} end)

    form =
    if socket.assigns[:accounting_transaction] == accounting_transaction do
      socket.assigns[:form] || to_form(changeset)
    else
      to_form(Accounting.change_accounting_transaction(accounting_transaction))
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:accounting_transaction, accounting_transaction)
     |> assign(:club_id, club_id)
     |> assign(:accounts, accounts)
     |> assign(:pending?, accounting_transaction.status == :pending)
     |> assign(:posted?, accounting_transaction.status == :posted)
     |> assign(:voided?, accounting_transaction.status == :voided)
     |> assign(:deleted?, accounting_transaction.status == :deleted)
     |> assign(:account_search, %{})
     |> assign(:account_results, %{})
     |> assign(:form, form)}
  end

  defp status_options(:draft) do
  [
    {"Entwurf", :draft},
    {"Zur Prüfung", :pending}
  ]
  end

  defp status_options(:deleted) do
  [
    {"Gelöscht", :draft},
    {"Entwurf", :draft}
  ]
  end

  defp status_options(:pending) do
    [
      {"Entwurf", :draft},
      {"Zur Prüfung", :pending},
      {"Gebucht", :posted}
    ]
  end

  defp status_options(:posted) do
    [{"Gebucht", :posted}]
  end

  defp status_options(:voided) do
    [{"Storniert", :voided}]
  end

  defp sphere_options do
  [
    {"Ideeller Bereich", :ideal},
    {"Vermögensverwaltung", :asset_management},
    {"Zweckbetrieb", :purpose_related},
    {"Wirtschaftlicher Geschäftsbetrieb", :commercial}
  ]
  end

  @impl true
  def handle_event("validate", %{"accounting_transaction" => accounting_transaction_params}, socket) do

    changeset =
      socket.assigns.accounting_transaction
      |> Accounting.change_accounting_transaction(accounting_transaction_params)
      |> Map.put(:action, :validate)

  {:noreply, assign(socket, form: to_form(changeset))}

  end

  def handle_event("save", %{"accounting_transaction" => accounting_transaction_params}, socket) do
    save_accounting_transaction(socket, socket.assigns.action, accounting_transaction_params)
  end

  @impl true
  def handle_event("add_entry", _, socket) do

    current_entries =
      case socket.assigns.form.params |> Map.get("entries") do
        nil ->
          # Entries aus dem bestehenden Changeset/Daten aufbauen
          socket.assigns.form.source
          |> Ecto.Changeset.get_field(:entries, [])
          |> Enum.with_index()
          |> Enum.map(fn {entry, index} ->
            {
              "#{index}",
              %{
                "account_id" => entry.account_id || "",
                "amount_input" => entry.amount_input || "",
                "description" => entry.description || "",
                "club_id" => entry.club_id || "",
                "id" => entry.id
              }
            }
          end)
          |> Enum.into(%{})
        entries ->
          entries
      end

    new_index = map_size(current_entries)

    attrs =
      socket.assigns.form.params
      |> Map.put("entries", Map.put(
        current_entries,
        "#{new_index}",
        %{"amount_input" => "", "account_id" => "", "description" => "", "club_id" => socket.assigns.club_id}
      ))

    changeset =
      Accounting.change_accounting_transaction(socket.assigns.accounting_transaction, attrs)

    {:noreply, assign(socket, form: to_form(changeset))}

  end

  @impl true
  def handle_event("search_account", %{"index" => index, "value" => value}, socket) do
    accounts = socket.assigns.accounts

    results =
      if String.length(value) < 2 do
        []
      else
        value_lower = String.downcase(value)
        accounts
        |> Enum.filter(fn {name, _id} ->
          String.contains?(String.downcase(name), value_lower)
        end)
        |> Enum.take(10)
      end

    {:noreply,
      socket
      |> update(:account_search, &Map.put(&1, index, value))
      |> update(:account_results, &Map.put(&1, index, results))}
  end

  defp get_account_name(accounts, account_id) do
    case Enum.find(accounts, fn {_name, id} -> id == account_id end) do
      {name, _id} -> name
      nil -> ""
    end
  end

  @impl true
  def handle_event("select_account", %{"index" => index, "id" => account_id, "name" => account_name}, socket) do
    entries =
      case socket.assigns.form.params |> Map.get("entries") do
        nil ->
          socket.assigns.form.source
          |> Ecto.Changeset.get_field(:entries, [])
          |> Enum.with_index()
          |> Enum.map(fn {entry, i} ->
            {"#{i}", %{
              "account_id" => entry.account_id || "",
              "amount_input" => entry.amount_input || "",
              "description" => entry.description || "",
              "club_id" => entry.club_id || "",
              "id" => entry.id
            }}
          end)
          |> Enum.into(%{})
        entries -> entries
      end

    updated_entries =
      Map.update(entries, index, %{}, fn entry ->
        Map.put(entry, "account_id", account_id)
      end)

    attrs = socket.assigns.form.params |> Map.put("entries", updated_entries)
    changeset = Accounting.change_accounting_transaction(socket.assigns.accounting_transaction, attrs)

    {:noreply,
      socket
      |> assign(:form, to_form(changeset))
      |> update(:account_search, &Map.put(&1, index, account_name))
      |> update(:account_results, &Map.put(&1, index, []))}
  end


  @impl true
  def handle_event("clear_account_search", %{"index" => index}, socket) do
    {:noreply,
      socket
      |> update(:account_search, &Map.put(&1, index, ""))
      |> update(:account_results, &Map.put(&1, index, []))}
  end

  @impl true
  def handle_event("remove_entry", %{"index" => index}, socket) do
    entries =
      socket.assigns.form.params
      |> Map.get("entries", %{})
      |> Map.delete(index)

    attrs =
      socket.assigns.form.params
      |> Map.put("entries", entries)

    changeset =
      Accounting.change_accounting_transaction(
        socket.assigns.accounting_transaction,
        attrs
      )

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  defp save_accounting_transaction(socket, :edit, accounting_transaction_params) do
      club_id = socket.assigns.club_id

        accounting_transaction_params =
          accounting_transaction_params
          |> Map.update("entries", %{}, fn entries ->
            entries
            |> Enum.map(fn {key, entry} ->
              {key, Map.put(entry, "club_id", club_id)}
            end)
            |> Enum.into(%{})
          end)


    case Accounting.update_accounting_transaction(socket.assigns.accounting_transaction, accounting_transaction_params) do
      {:ok, accounting_transaction} ->
        notify_parent({:saved, accounting_transaction})

        {:noreply,
         socket
         |> put_flash(:info, "Buchung erfolgreich aktualisiert")
         |> push_navigate(to: socket.assigns.navigate)}

         {:error, :immutable} ->
            {:noreply,
              socket
              |> put_flash(:error, "Diese Buchung kann nicht mehr bearbeitet werden.")}
          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}

    end
  end

  defp save_accounting_transaction(socket, :new, accounting_transaction_params) do
    accounting_transaction_params = Enum.into(accounting_transaction_params, %{"club_id" => socket.assigns.club_id})

      club_id = socket.assigns.club_id

      # club_id zu jeder Entry in den Params hinzufügen
      accounting_transaction_params =
        accounting_transaction_params
        |> Map.put("club_id", club_id)
        |> Map.update("entries", %{}, fn entries ->
          entries
          |> Enum.map(fn {key, entry} ->
            {key, Map.put(entry, "club_id", club_id)}
          end)
          |> Enum.into(%{})
          end)


    case Accounting.create_accounting_transaction(accounting_transaction_params) do
      {:ok, accounting_transaction} ->
        notify_parent({:saved, accounting_transaction})

        {:noreply,
         socket
         |> put_flash(:info, "Buchung erfolgreich erstellt")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp calculate_sum(form) do

    entries =
      case Map.get(form.params, "entries") do
        # Params vorhanden — Nutzer hat bereits interagiert
        entries when is_map(entries) and map_size(entries) > 0 ->
          Map.values(entries)

        # Params leer — initialer Load, Entries aus Changeset lesen
        _ ->
          form.source
          |> Ecto.Changeset.get_field(:entries, [])
          |> Enum.map(fn entry ->
            %{
              "amount_input" =>
                case entry.amount do
                  %Money{} = money ->
                    money.amount
                    |> Decimal.new()
                    |> Decimal.to_string()
                  _ ->
                    entry.amount_input || ""
                end
            }
          end)
      end

    Enum.reduce(entries, Money.new(:EUR, 0), fn entry, acc ->
      case entry["amount_input"] do
        nil -> acc
        "" -> acc
        amount ->
          _normalized = String.replace(amount, ",", ".")
          case Decimal.parse(amount) do
            {decimal, _} -> Money.add!(acc, Money.new(:EUR, decimal))
            :error -> acc
          end
      end
    end)
  end

  defp display_money(money_struct) do
    case Money.to_string(money_struct) do
      {:ok, string} -> string
      _ -> "0,00 €"
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
