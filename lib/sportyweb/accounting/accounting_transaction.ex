defmodule Sportyweb.Accounting.AccountingTransaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Organization.Club
  alias Sportyweb.Accounting.Entry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounting_transactions" do
    belongs_to(:club, Club)
    has_many(:entries, Entry, on_replace: :delete)

    field :description, :string
    field :voucher_number, :string
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
    |> cast(attrs, [:club_id, :description, :voucher_number, :reference, :status, :sphere])
    |> validate_required([:club_id, :description])
    |> cast_assoc(:entries, with: &Entry.form_changeset/2)
    |> unique_constraint(:voucher_number,
    name: :accounting_transactions_club_id_voucher_number_index,
    message: "Diese Belegnummer existiert bereits für diesen Verein")
  end

  def pending_changeset(transaction) do
  transaction |> change(status: :pending)
  end

  def post_changeset(transaction) do
    transaction
    |> change(status: :posted)
    |> change(posted_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> validate_balanced_entries()  # Summe der Entries muss 0 ergeben
  end

  def draft_changeset(transaction) do
    transaction |> change(status: :draft)
  end

  # def update_description_changeset(accounting_transaction, attrs) do
  #   accounting_transaction
  #   |> cast(attrs, [:description])
  #   |> validate_required([:description])
  # end

  def void_changeset(transaction) do
    transaction |> change(status: :voided)
  end

  def reversal_changeset(accounting_transaction, attrs) do
    accounting_transaction
    |> cast(attrs, [:club_id, :description, :voucher_number, :reference, :status, :sphere, :posted_at])
    |> validate_required([:club_id, :description, :voucher_number])
    |> cast_assoc(:entries, with: &Entry.changeset/2)
  end

  defp validate_balanced_entries(changeset) do
    entries = changeset
      |> Ecto.Changeset.get_field(:entries)
      |> List.wrap()

    # cond do
    #   length(entries) < 2 ->
    #     add_error(changeset, :entries, "Fehler: Ein Buchungssatz muss mindestens zwei Buchungseinträge enthalten!")

    #   Enum.reduce(entries, Money.new(:EUR, 0), fn entry, acc ->
    #     Money.add!(acc, entry.amount)
    #   end) != Money.new(:EUR, 0) ->
    #     add_error(changeset, :entries, "Fehler ein Buchungssatz muss ausgeglichen sein; die Summe aller Buchungseinträge muss 0 EUR ergeben")

    #   true ->
    #     changeset
    # end

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

end
