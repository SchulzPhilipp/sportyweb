defmodule Sportyweb.Accounting.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Organization.Club
  alias Sportyweb.Accounting.Account
  alias Sportyweb.Accounting.AccountingTransaction


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "entries" do
    belongs_to(:club, Club)
    belongs_to(:account, Account)
    belongs_to(:accounting_transaction, AccountingTransaction)

    field :description, :string
    field :amount, Money.Ecto.Composite.Type, default_currency: :EUR
    field :amount_input, :string, virtual: true #virtuelles Feld für das Formular

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:account_id, :amount, :description, :club_id, :accounting_transaction_id])
    |> validate_required([:account_id, :amount, :club_id])
    |> validate_length(:description, max: 250)
    |> assoc_constraint(:account)
  end

  @doc false
  def form_changeset(entry, attrs) do
    entry
    |> cast(attrs, [:account_id, :amount_input, :description, :club_id])
    |> normalize_amount_input()
    |> validate_required([:account_id, :amount_input])
    |> validate_length(:description, max: 250)
    |> parse_amount()
    |> assoc_constraint(:account)
  end

  defp normalize_amount_input(changeset) do
    case get_change(changeset, :amount_input) do
      nil -> changeset
      "" -> changeset
      amount_input ->
        normalized = String.replace(amount_input, ",", ".")
        put_change(changeset, :amount_input, normalized)
    end
  end

  defp parse_amount(changeset) do
    case get_field(changeset, :amount_input) do
      nil -> changeset
      "" -> add_error(changeset, :amount_input, "darf nicht leer sein")
      amount_str ->
        case Decimal.parse(amount_str) do
          {decimal, _} ->
            put_change(changeset, :amount, Money.new(:EUR, decimal))
          :error ->
            add_error(changeset, :amount_input, "ungültiger Betrag")
        end
    end
  end

end
