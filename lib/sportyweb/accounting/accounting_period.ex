defmodule Sportyweb.Accounting.AccountingPeriod do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sportyweb.Organization.Club
  alias Sportyweb.Accounting.AccountingTransaction

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounting_periods" do
    belongs_to(:club, Club)
    has_many(:accounting_transactions, AccountingTransaction)

    field :name, :string
    field :starts_on, :date
    field :ends_on, :date
    field :transaction_counter, :integer, default: 0
    field :status, Ecto.Enum,
      values: [:open, :closing, :closed],
      default: :open

    timestamps(type: :utc_datetime)
  end

  def status_labels do
    %{
      open:     "Offen",
      closing:  "In Abschluss",
      closed:   "Abgeschlossen"
    }
  end


  def status_options do
    Enum.map(status_labels(), fn {k, v} -> {v, k} end)
  end


  @doc false
  def changeset(accounting_period, attrs) do
    accounting_period
    |> cast(attrs, [:club_id, :name, :starts_on, :ends_on, :status])
    |> validate_required([:club_id, :name, :starts_on, :ends_on])
    |> validate_date_range()
    |> unique_constraint(:name, name: :accounting_periods_club_id_name_index)
  end

  defp validate_date_range(changeset) do
    starts_on = get_field(changeset, :starts_on)
    ends_on   = get_field(changeset, :ends_on)

    if starts_on && ends_on && Date.compare(starts_on, ends_on) != :lt do
      add_error(changeset, :ends_on, "muss nach dem Startdatum liegen")
    else
      changeset
    end
  end

end
