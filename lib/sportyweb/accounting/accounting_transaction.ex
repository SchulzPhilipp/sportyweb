defmodule Sportyweb.Accounting.AccountingTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Repo
  alias Sportyweb.Organization.Club
  alias Sportyweb.Accounting.Entry
  alias Sportyweb.Accounting.AccountingPeriod

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounting_transactions" do
    belongs_to(:club, Club)
    belongs_to(:accounting_period, AccountingPeriod)
    has_many(:entries, Entry, on_replace: :delete)

    field :description, :string
    field :transaction_number, :string
    field :document_date, :date
    field :reference, :string
    field :posted_at, :utc_datetime
    field :deleted_at, :utc_datetime
    field :status, Ecto.Enum,
      values: [:draft, :pending, :posted, :voided, :deleted],
      default: :draft
    field :sphere, Ecto.Enum,
      values: [:ideal, :asset_management, :purpose_related, :commercial],
      default: :ideal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(accounting_transaction, attrs) do
    accounting_transaction
    |> cast(attrs, [:club_id, :accounting_period_id, :document_date, :description, :transaction_number, :reference, :status, :sphere, :posted_at])
    |> validate_required([:club_id, :accounting_period_id, :document_date, :description])
    |> cast_assoc(:entries, with: &Entry.form_changeset/2)
    |> validate_period_open()
    |> unique_constraint(:transaction_number,
      name: :accounting_transactions_club_id_transaction_number_index,
      message: "Diese Buchungsnummer existiert bereits für diesen Verein")
  end

  def pending_changeset(transaction) do
  transaction |> change(status: :pending)
  end

  def post_changeset(transaction) do
    transaction
    |> change(status: :posted)
    |> change(posted_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> validate_balanced_entries()
  end

  def draft_changeset(transaction) do
    transaction |> change(status: :draft)
  end

  def void_changeset(transaction) do
    transaction |> change(status: :voided)
  end

  def reversal_changeset(accounting_transaction, attrs) do
    accounting_transaction
    |> cast(attrs, [:club_id, :accounting_period_id, :description, :document_date, :transaction_number, :reference, :status, :sphere, :posted_at])
    |> validate_required([:club_id, :document_date, :description, :transaction_number])
    |> cast_assoc(:entries, with: &Entry.changeset/2)
  end

  defp validate_balanced_entries(changeset) do
    entries = changeset
      |> Ecto.Changeset.get_field(:entries)
      |> List.wrap()

     sum =
        Enum.reduce(entries, Decimal.new(0), fn entry, acc ->
          Decimal.add(acc, entry.amount.amount)
        end)

      if Decimal.equal?(Decimal.round(sum, 2), Decimal.new(0)) do
        changeset
      else
        add_error(changeset, :entries,
          "Fehler: Ein Buchungssatz muss ausgeglichen sein;
           die Summe aller Buchungseinträge muss 0 EUR ergeben")
     end

  end

  defp validate_period_open(changeset) do
    case get_field(changeset, :accounting_period_id) do
      nil -> changeset
      period_id ->
        period = Repo.get(AccountingPeriod, period_id)
        if period && period.status == :closed do
          add_error(changeset, :accounting_period_id,
            "Diese Buchungsperiode ist abgeschlossen. Es können keine Buchungen mehr vorgenommen werden.")
        else
          changeset
        end
    end
  end

end
