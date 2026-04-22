# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Sportyweb.Repo.insert!(%Sportyweb.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query

alias Sportyweb.Repo

alias Sportyweb.Accounts
alias Sportyweb.Accounts.User
alias Sportyweb.Asset
alias Sportyweb.Asset.Equipment
alias Sportyweb.Asset.Location
alias Sportyweb.Calendar.Event
alias Sportyweb.Finance
alias Sportyweb.Finance.Fee
alias Sportyweb.Finance.Subsidy
alias Sportyweb.Legal.Contract
alias Sportyweb.Organization
alias Sportyweb.Organization.Club
alias Sportyweb.Organization.Department
alias Sportyweb.Organization.Group
alias Sportyweb.Personal
alias Sportyweb.Personal.Contact
alias Sportyweb.Polymorphic.Email
alias Sportyweb.Polymorphic.FinancialData
alias Sportyweb.Polymorphic.InternalEvent
alias Sportyweb.Polymorphic.Note
alias Sportyweb.Polymorphic.Phone
alias Sportyweb.Polymorphic.PostalAddress
alias Sportyweb.Accounting.Accountclass
alias Sportyweb.Accounting.Accountgroup
alias Sportyweb.Accounting.Accounttype
alias Sportyweb.Accounting.Account
alias Sportyweb.Accounting.Entry
alias Sportyweb.Accounting.AccountingTransaction
alias Sportyweb.Accounting.AccountingPeriod

alias Sportyweb.RBAC.Role.ApplicationRole
alias Sportyweb.RBAC.Role.ClubRole
alias Sportyweb.RBAC.Role.DepartmentRole
alias Sportyweb.RBAC.Role.RolePermissionMatrix, as: RPM

###################################
# Helper functions

defmodule Sportyweb.SeedHelper do
  def get_random_string(length) do
    :crypto.strong_rand_bytes(100) |> Base.encode64() |> String.slice(0, length)
  end

  def get_random_email do
    %Email{
      type: Email.get_valid_types() |> Enum.map(fn type -> type[:value] end) |> Enum.random(),
      address: if(:rand.uniform() < 0.7, do: Faker.Internet.email(), else: "")
    }
  end

  def get_random_financial_data do
    random_name = "#{Faker.Person.last_name()}, #{Faker.Person.first_name()}"

    if :rand.uniform() < 0.9 do
      %FinancialData{
        type: "direct_debit",
        direct_debit_account_holder: random_name,
        direct_debit_iban: "DE06495352657836424132",
        direct_debit_institute: "Beispielbank"
      }
    else
      %FinancialData{
        type: "invoice",
        invoice_recipient: random_name,
        invoice_additional_information: ""
      }
    end
  end

  def get_random_internal_event do
    %InternalEvent{
      is_recurring: true,
      commission_date: ~D[2020-01-01],
      archive_date: nil,
      frequency: "year",
      interval: 1
    }
  end

  def get_random_phone do
    %Phone{
      type: Phone.get_valid_types() |> Enum.map(fn type -> type[:value] end) |> Enum.random(),
      number: if(:rand.uniform() < 0.7, do: Faker.Phone.EnUs.phone(), else: "")
    }
  end

  def get_random_postal_address do
    %PostalAddress{
      street: Faker.Address.street_name(),
      street_number: Faker.Address.building_number(),
      street_additional_information: "",
      zipcode: Faker.Address.zip(),
      city: Faker.Address.city(),
      country:
        PostalAddress.get_valid_countries()
        |> Enum.map(fn country -> country[:value] end)
        |> Enum.random()
    }
  end

  def get_random_note do
    %Note{
      content: if(:rand.uniform() < 0.7, do: Faker.Lorem.paragraph(), else: "")
    }
  end
end

###################################
# Add Users
# Only in the dev environment!

if Mix.env() in [:dev] do
  Accounts.register_user(%{
    email: "stefan.strecker@fernuni-hagen.de",
    password: "NTU5MTM5NGNmZjY"
  })

  Accounts.register_user(%{
    email: "sven.christ@fernuni-hagen.de",
    password: "ZThjNWY2NTQ3OGQ"
  })

  Accounts.register_user(%{
    email: "bastian.kres@fernuni-hagen.de",
    password: "MzU0MmJiZWI4ZmN"
  })

  Accounts.register_user(%{
    email: "TesterSportywebAdmin@test.de",
    password: "testtest"
  })

  Accounts.register_user(%{
    email: "timing_attack_dummy@sportyweb.de",
    password: "zczZjRMGI3MTNlM"
  })

  User
  |> Repo.all()
  |> Enum.map(&Repo.update!(User.confirm_changeset(&1)))
end

###################################
# Add Club 1

club_1 =
  Repo.insert!(%Club{
    name: "FC Bayern München",
    reference_number: "FCB",
    description:
      "One morning, when Gregor Samsa woke from troubled dreams, he found himself transformed in his bed into a horrible vermin.",
    website_url: "https://fcbayern.com/",
    foundation_date: ~D[1900-02-27],
    emails: [%Email{type: "organization", address: "service@fcbayern.com"}],
    phones: [%Phone{type: "organization", number: "+49 89 699 31-0"}],
    financial_data: [Sportyweb.SeedHelper.get_random_financial_data()],
    notes: [Sportyweb.SeedHelper.get_random_note()]
  })

department =
  Repo.insert!(%Department{
    club: club_1,
    name: "Fußball Herren",
    creation_date: ~D[1900-03-01],
    emails: [Sportyweb.SeedHelper.get_random_email()],
    phones: [Sportyweb.SeedHelper.get_random_phone()],
    notes: [Sportyweb.SeedHelper.get_random_note()]
  })

Repo.insert!(%Group{
  department: department,
  name: "1. Herrenmannschaft",
  creation_date: ~D[1900-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "2. Herrenmannschaft",
  creation_date: ~D[1901-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "A-Jugend",
  creation_date: ~D[1902-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "B-Jugend",
  creation_date: ~D[1903-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "Kinder",
  creation_date: ~D[1904-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

department =
  Repo.insert!(%Department{
    club: club_1,
    name: "Fußball Damen",
    creation_date: ~D[1905-03-01],
    emails: [Sportyweb.SeedHelper.get_random_email()],
    phones: [Sportyweb.SeedHelper.get_random_phone()],
    notes: [%Note{}]
  })

Repo.insert!(%Group{
  department: department,
  name: "1. Damenmannschaft",
  creation_date: ~D[1905-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "2. Damenmannschaft",
  creation_date: ~D[1906-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "A-Jugend",
  creation_date: ~D[1907-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "B-Jugend",
  creation_date: ~D[1908-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "Kinder",
  creation_date: ~D[1909-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Department{
  club: club_1,
  name: "Basketball",
  creation_date: ~D[1910-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Department{
  club: club_1,
  name: "Handball",
  creation_date: ~D[1915-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Department{
  club: club_1,
  name: "Schach",
  creation_date: ~D[1920-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

###################################
# Add Club 2

club_2 =
  Repo.insert!(%Club{
    name: "1. FC Köln",
    reference_number: "Effzeh",
    description:
      "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor.",
    website_url: "https://fc.de/",
    foundation_date: ~D[1948-02-13],
    emails: [%Email{type: "organization", address: "service@fc.de"}],
    phones: [%Phone{type: "organization", number: "0221 99 1948 0"}],
    financial_data: [Sportyweb.SeedHelper.get_random_financial_data()],
    notes: [Sportyweb.SeedHelper.get_random_note()]
  })

department =
  Repo.insert!(%Department{
    club: club_2,
    name: "Fußball Herren",
    creation_date: ~D[1948-03-01],
    emails: [Sportyweb.SeedHelper.get_random_email()],
    phones: [Sportyweb.SeedHelper.get_random_phone()],
    notes: [Sportyweb.SeedHelper.get_random_note()]
  })

Repo.insert!(%Group{
  department: department,
  name: "1. Herrenmannschaft",
  creation_date: ~D[1948-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "2. Herrenmannschaft",
  creation_date: ~D[1949-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "A-Jugend",
  creation_date: ~D[1950-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "B-Jugend",
  creation_date: ~D[1951-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "Kinder",
  creation_date: ~D[1952-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

department =
  Repo.insert!(%Department{
    club: club_2,
    name: "Fußball Damen",
    creation_date: ~D[1950-03-01],
    emails: [Sportyweb.SeedHelper.get_random_email()],
    phones: [Sportyweb.SeedHelper.get_random_phone()],
    notes: [Sportyweb.SeedHelper.get_random_note()]
  })

Repo.insert!(%Group{
  department: department,
  name: "1. Damenmannschaft",
  creation_date: ~D[1950-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "2. Damenmannschaft",
  creation_date: ~D[1951-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "A-Jugend",
  creation_date: ~D[1952-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "B-Jugend",
  creation_date: ~D[1953-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Group{
  department: department,
  name: "Kinder",
  creation_date: ~D[1954-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Department{
  club: club_2,
  name: "Handball",
  creation_date: ~D[1955-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Department{
  club: club_2,
  name: "Tischtennis",
  creation_date: ~D[1960-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

###################################
# Add Club 3

club_3 =
  Repo.insert!(%Club{
    name: "FC St. Pauli",
    reference_number: "-",
    description:
      "A wonderful serenity has taken possession of my entire soul, like these sweet mornings of spring which I enjoy with my whole heart.",
    website_url: "https://www.fcstpauli.com/",
    foundation_date: ~D[1910-05-15],
    emails: [%Email{type: "organization", address: "info@fcstpauli.com"}],
    phones: [%Phone{type: "organization", number: "040 - 317 874 0"}],
    financial_data: [Sportyweb.SeedHelper.get_random_financial_data()],
    notes: [Sportyweb.SeedHelper.get_random_note()]
  })

###################################
# Add Club 4

club_4 =
  Repo.insert!(%Club{
    name: "Leerer Verein",
    reference_number: "",
    description: "",
    website_url: "",
    foundation_date: ~D[2020-04-01],
    emails: [%Email{type: "organization", address: ""}],
    phones: [%Phone{type: "organization", number: ""}],
    financial_data: [Sportyweb.SeedHelper.get_random_financial_data()],
    notes: [Sportyweb.SeedHelper.get_random_note()]
  })

###################################
# Add Club Test

testclub =
  Repo.insert!(%Club{
    name: "TestVerein",
    reference_number: "",
    website_url: "",
    foundation_date: ~D[2023-03-01],
    emails: [Sportyweb.SeedHelper.get_random_email()],
    phones: [Sportyweb.SeedHelper.get_random_phone()],
    financial_data: [Sportyweb.SeedHelper.get_random_financial_data()],
    notes: [Sportyweb.SeedHelper.get_random_note()]
  })

Repo.insert!(%Department{
  club: testclub,
  name: "TestAbteilung1",
  creation_date: ~D[2023-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

Repo.insert!(%Department{
  club: testclub,
  name: "TestAbteilung2",
  creation_date: ~D[2023-03-01],
  emails: [Sportyweb.SeedHelper.get_random_email()],
  phones: [Sportyweb.SeedHelper.get_random_phone()],
  notes: [Sportyweb.SeedHelper.get_random_note()]
})

###################################
# Add Roles

for [type, struct] <- [
      [:application, %ApplicationRole{}],
      [:club, %ClubRole{}],
      [:department, %DepartmentRole{}]
    ] do
  for rolename <- RPM.get_role_names(type) do
    struct |> Map.put(:name, rolename) |> Repo.insert!()
  end
end

# Seed sportyweb admins
ar =
  ApplicationRole
  |> Repo.all()
  |> Enum.filter(&String.contains?(&1.name, "Sportyweb"))
  |> Enum.at(0)

for user <- Repo.all(User) do
  Sportyweb.RBAC.UserRole.create_user_application_role(%{
    user_id: user.id,
    applicationrole_id: ar.id
  })
end

###################################
# Randomly generated associated data

Organization.list_clubs(departments: [:fees, groups: :fees])
|> Enum.with_index()
|> Enum.each(fn {club, _club_index} ->
  # No data for the "empty club"!
  if club.id != club_4.id do
    # Subsidies

    subsidy =
      Repo.insert!(%Subsidy{
        club_id: club.id,
        name: "Zuschuss Sozialhilfeempfänger",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, 30),
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}]
      })

    # Fees: General - Club

    fee_pensioners =
      Repo.insert!(%Fee{
        club_id: club.id,
        is_general: true,
        type: "club",
        name: "Jahresmitgl. Verein Senioren",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(40..60)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: 66,
        maximum_age_in_years: nil,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}]
      })

    fee_adults =
      Repo.insert!(%Fee{
        club_id: club.id,
        successor_id: fee_pensioners.id,
        is_general: true,
        type: "club",
        name: "Jahresmitgl. Verein Erwachsene (Vollmitglied)",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(60..200)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: 18,
        maximum_age_in_years: 65,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}]
      })

    Repo.insert!(%Fee{
      club_id: club.id,
      subsidy_id: subsidy.id,
      successor_id: fee_pensioners.id,
      is_general: true,
      type: "club",
      name: "Jahresmitgl. Verein Erwachsene (Unterstützungsempfänger)",
      reference_number: Sportyweb.SeedHelper.get_random_string(3),
      description: "",
      amount: Money.new(:EUR, Enum.random(30..50)),
      amount_one_time: Money.new(:EUR, 0),
      is_for_contact_group_contacts_only: false,
      minimum_age_in_years: 18,
      maximum_age_in_years: 65,
      internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
      notes: [%Note{}]
    })

    fee_teenagers =
      Repo.insert!(%Fee{
        club_id: club.id,
        successor_id: fee_adults.id,
        is_general: true,
        type: "club",
        name: "Jahresmitgl. Verein Jugendliche",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(30..40)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: 13,
        maximum_age_in_years: 17,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}]
      })

    Repo.insert!(%Fee{
      club_id: club.id,
      successor_id: fee_teenagers.id,
      is_general: true,
      type: "club",
      name: "Jahresmitgl. Verein Kinder",
      reference_number: Sportyweb.SeedHelper.get_random_string(3),
      description: "",
      amount: Money.new(:EUR, Enum.random(10..25)),
      amount_one_time: Money.new(:EUR, 0),
      is_for_contact_group_contacts_only: false,
      minimum_age_in_years: 0,
      maximum_age_in_years: 12,
      internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
      notes: [%Note{}]
    })

    # Fees: General - Departments

    fee_adults =
      Repo.insert!(%Fee{
        club_id: club.id,
        is_general: true,
        type: "department",
        name: "Allg. Jahresmitgl. Abteilung Erwachsene & Senioren",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(15..25)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: 18,
        maximum_age_in_years: nil,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}]
      })

    Repo.insert!(%Fee{
      club_id: club.id,
      successor_id: fee_adults.id,
      is_general: true,
      type: "department",
      name: "Allg. Jahresmitgl. Abteilung Kinder & Jugendliche",
      reference_number: Sportyweb.SeedHelper.get_random_string(3),
      description: "",
      amount: Money.new(:EUR, Enum.random(5..15)),
      amount_one_time: Money.new(:EUR, 0),
      is_for_contact_group_contacts_only: false,
      minimum_age_in_years: 0,
      maximum_age_in_years: 17,
      internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
      notes: [%Note{}]
    })

    # Fees: General - Groups

    fee_adults =
      Repo.insert!(%Fee{
        club_id: club.id,
        is_general: true,
        type: "group",
        name: "Allg. Jahresmitgl. Gruppe Erwachsene & Senioren",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(15..25)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: 18,
        maximum_age_in_years: nil,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}]
      })

    Repo.insert!(%Fee{
      club_id: club.id,
      successor_id: fee_adults.id,
      is_general: true,
      type: "group",
      name: "Allg. Jahresmitgl. Gruppe Kinder & Jugendliche",
      reference_number: Sportyweb.SeedHelper.get_random_string(3),
      description: "",
      amount: Money.new(:EUR, Enum.random(5..15)),
      amount_one_time: Money.new(:EUR, 0),
      is_for_contact_group_contacts_only: false,
      minimum_age_in_years: 0,
      maximum_age_in_years: 17,
      internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
      notes: [%Note{}]
    })

    # Fees: General - Events

    fee_adults =
      Repo.insert!(%Fee{
        club_id: club.id,
        is_general: true,
        type: "event",
        name: "Allg. Teilnahmegebühr Einführungskurs Fußball Erwachsene",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(25..40)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: 18,
        maximum_age_in_years: 65,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}]
      })

    Repo.insert!(%Fee{
      club_id: club.id,
      successor_id: fee_adults.id,
      is_general: true,
      type: "event",
      name: "Allg. Teilnahmegebühr Einführungskurs Fußball Kinder",
      reference_number: Sportyweb.SeedHelper.get_random_string(3),
      description: "",
      amount: Money.new(:EUR, Enum.random(20..25)),
      amount_one_time: Money.new(:EUR, 0),
      is_for_contact_group_contacts_only: false,
      minimum_age_in_years: 0,
      maximum_age_in_years: 12,
      internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
      notes: [%Note{}]
    })

    # Fees: General - Equipment

    Repo.insert!(%Fee{
      club_id: club.id,
      is_general: true,
      type: "equipment",
      name: "Allg. Ausleihgebühr Fußbälle",
      reference_number: Sportyweb.SeedHelper.get_random_string(3),
      description: "",
      amount: Money.new(:EUR, 3),
      amount_one_time: Money.new(:EUR, 0),
      is_for_contact_group_contacts_only: false,
      minimum_age_in_years: nil,
      maximum_age_in_years: nil,
      internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
      notes: [%Note{}]
    })

    Repo.insert!(%Fee{
      club_id: club.id,
      is_general: true,
      type: "equipment",
      name: "Allg. Ausleihgebühr Fußballschuhe Kinder & Jugendliche",
      reference_number: Sportyweb.SeedHelper.get_random_string(3),
      description: "",
      amount: Money.new(:EUR, 2),
      amount_one_time: Money.new(:EUR, 0),
      is_for_contact_group_contacts_only: false,
      minimum_age_in_years: 0,
      maximum_age_in_years: 17,
      internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
      notes: [%Note{}]
    })

    # Fees: Specific - Departments

    Organization.list_departments(club.id)
    |> Enum.with_index()
    |> Enum.each(fn {department, _department_index} ->
      fee_adults =
        Repo.insert!(%Fee{
          club_id: club.id,
          is_general: false,
          type: "department",
          name: "Spez. Jahresmitgl. Abteilung Erwachsene & Senioren",
          reference_number: Sportyweb.SeedHelper.get_random_string(3),
          description: "",
          amount: Money.new(:EUR, Enum.random(5..25)),
          amount_one_time: Money.new(:EUR, 0),
          is_for_contact_group_contacts_only: false,
          minimum_age_in_years: 18,
          maximum_age_in_years: nil,
          internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
          notes: [%Note{}],
          departments: [department]
        })

      Repo.insert!(%Fee{
        club_id: club.id,
        successor_id: fee_adults.id,
        is_general: false,
        type: "department",
        name: "Spez. Jahresmitgl. Abteilung Kinder & Jugendliche",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(5..10)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: 0,
        maximum_age_in_years: 17,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}],
        departments: [department]
      })

      # Fees: Specific - Groups

      Organization.list_groups(department.id)
      |> Enum.with_index()
      |> Enum.each(fn {group, _group_index} ->
        fee_adults =
          Repo.insert!(%Fee{
            club_id: club.id,
            is_general: false,
            type: "group",
            name: "Spez. Jahresmitgl. Gruppe Erwachsene & Senioren",
            reference_number: Sportyweb.SeedHelper.get_random_string(3),
            description: "",
            amount: Money.new(:EUR, Enum.random(15..25)),
            amount_one_time: Money.new(:EUR, 0),
            is_for_contact_group_contacts_only: false,
            minimum_age_in_years: 18,
            maximum_age_in_years: nil,
            internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
            notes: [%Note{}],
            groups: [group]
          })

        Repo.insert!(%Fee{
          club_id: club.id,
          successor_id: fee_adults.id,
          is_general: false,
          type: "group",
          name: "Spez. Jahresmitgl. Gruppe Kinder & Jugendliche",
          reference_number: Sportyweb.SeedHelper.get_random_string(3),
          description: "",
          amount: Money.new(:EUR, Enum.random(5..15)),
          amount_one_time: Money.new(:EUR, 0),
          is_for_contact_group_contacts_only: false,
          minimum_age_in_years: 0,
          maximum_age_in_years: 17,
          internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
          notes: [%Note{}],
          groups: [group]
        })
      end)
    end)

    # Contacts & Contracts

    for _i <- 0..Enum.random(20..50) do
      # Use the context function instead of Repo.insert!() to invoke the changeset which sets the name.
      {:ok, %Contact{} = contact} =
        Personal.create_contact(%{
          club_id: club.id,
          type: if(:rand.uniform() < 0.8, do: "person", else: "organization"),
          organization_name:
            "#{Faker.Company.buzzword_prefix()} #{Faker.Industry.sub_sector()} #{Faker.Company.buzzword_prefix()}",
          organization_type:
            Contact.get_valid_organization_types()
            |> Enum.map(fn organization_type -> organization_type[:value] end)
            |> Enum.random(),
          person_last_name: Faker.Person.last_name(),
          person_first_name_1: Faker.Person.first_name(),
          person_first_name_2:
            if(:rand.uniform() < 0.80, do: "", else: Faker.Person.first_name()),
          person_gender:
            Contact.get_valid_genders()
            |> Enum.map(fn gender -> gender[:value] end)
            |> Enum.random(),
          person_birthday: Faker.Date.date_of_birth(6..99),
          postal_addresses: [Map.from_struct(Sportyweb.SeedHelper.get_random_postal_address())],
          emails: [Map.from_struct(Sportyweb.SeedHelper.get_random_email())],
          phones: [Map.from_struct(Sportyweb.SeedHelper.get_random_phone())],
          financial_data: [Map.from_struct(Sportyweb.SeedHelper.get_random_financial_data())],
          notes: [Map.from_struct(Sportyweb.SeedHelper.get_random_note())]
        })

      if contact.type == "person" do
        if :rand.uniform() < 0.5 do
          # Select a random fee that works with this combination of club & contact
          fee = Finance.list_contract_fee_options(club, contact.id) |> Enum.random()

          Repo.insert!(%Contract{
            club_id: club.id,
            contact_id: contact.id,
            fee_id: fee.id,
            signing_date: ~D[2021-11-28],
            start_date: ~D[2022-01-01],
            termination_date: nil,
            archive_date: nil,
            clubs: [club]
          })
        end

        if Enum.any?(club.departments) do
          department = club.departments |> Enum.random()

          if :rand.uniform() < 0.3 do
            # Select a random fee that works with this combination of club & department
            fee = Finance.list_contract_fee_options(department, contact.id) |> Enum.random()

            Repo.insert!(%Contract{
              club_id: club.id,
              contact_id: contact.id,
              fee_id: fee.id,
              signing_date: ~D[2021-11-28],
              start_date: ~D[2022-01-01],
              termination_date: nil,
              archive_date: nil,
              departments: [department]
            })
          end

          if Enum.any?(department.groups) do
            group = department.groups |> Enum.random()

            if :rand.uniform() < 0.3 do
              # Select a random fee that works with this combination of club & group
              fee = Finance.list_contract_fee_options(group, contact.id) |> Enum.random()

              Repo.insert!(%Contract{
                club_id: club.id,
                contact_id: contact.id,
                fee_id: fee.id,
                signing_date: ~D[2021-11-28],
                start_date: ~D[2022-01-01],
                termination_date: nil,
                archive_date: nil,
                groups: [group]
              })
            end
          end
        end
      end
    end

    # Locations

    for i <- 0..Enum.random(3..7) do
      location =
        Repo.insert!(%Location{
          club_id: club.id,
          name: if(i == 0, do: "Zentrale", else: "Standort #{i + 1}"),
          reference_number: String.pad_leading("#{i + 1}", 3, "0"),
          description: if(:rand.uniform() < 0.65, do: Faker.Lorem.paragraph(), else: ""),
          postal_addresses: [Sportyweb.SeedHelper.get_random_postal_address()],
          emails: [Sportyweb.SeedHelper.get_random_email()],
          phones: [Sportyweb.SeedHelper.get_random_phone()],
          notes: [Sportyweb.SeedHelper.get_random_note()]
        })

      if i == 0, do: Organization.update_club(club, %{location_id: location.id})

      # Fees: Specific - Location

      Repo.insert!(%Fee{
        club_id: club.id,
        is_general: false,
        type: "location",
        name: "Spez. Standortmiete #{location.reference_number}",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(10..150)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: nil,
        maximum_age_in_years: nil,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}],
        locations: [location]
      })

      # Equipment

      for _j <- 0..Enum.random(1..30) do
        equipment =
          Repo.insert!(%Equipment{
            location_id: location.id,
            name: Faker.Commerce.product_name(),
            reference_number: Sportyweb.SeedHelper.get_random_string(5),
            serial_number: Sportyweb.SeedHelper.get_random_string(15),
            description: if(:rand.uniform() < 0.50, do: Faker.Lorem.paragraph(), else: ""),
            purchase_date: Faker.Date.backward(Enum.random(300..2000)),
            commission_date: Faker.Date.backward(Enum.random(0..299)),
            decommission_date:
              if(:rand.uniform() < 0.65,
                do: Faker.Date.forward(Enum.random(100..2000)),
                else: nil
              ),
            emails: [Sportyweb.SeedHelper.get_random_email()],
            phones: [Sportyweb.SeedHelper.get_random_phone()],
            notes: [Sportyweb.SeedHelper.get_random_note()]
          })

        # Fees: Specific - Equipment

        Repo.insert!(%Fee{
          club_id: club.id,
          is_general: false,
          type: "equipment",
          name: "Spez. Ausleihgebühr Equipment #{equipment.reference_number}",
          reference_number: Sportyweb.SeedHelper.get_random_string(3),
          description: "",
          amount: Money.new(:EUR, Enum.random(10..150)),
          amount_one_time: Money.new(:EUR, 0),
          is_for_contact_group_contacts_only: false,
          minimum_age_in_years: nil,
          maximum_age_in_years: nil,
          internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
          notes: [%Note{}],
          equipment: [equipment]
        })
      end
    end

    # Events

    locations = Asset.list_locations(club.id)

    for _i <- 0..Enum.random(10..30) do
      event =
        Repo.insert!(%Event{
          club_id: club.id,
          name: "Verans.: #{Faker.Lorem.characters(Enum.random(5..15))}",
          reference_number: Sportyweb.SeedHelper.get_random_string(5),
          status: "public",
          description: if(:rand.uniform() < 0.65, do: Faker.Lorem.paragraph(), else: ""),
          minimum_participants: 0,
          maximum_participants: Enum.random(3..40),
          minimum_age_in_years: 0,
          maximum_age_in_years: Enum.random(5..100),
          venue_type:
            Event.get_valid_venue_types()
            |> Enum.map(fn venue_type -> venue_type[:value] end)
            |> Enum.random(),
          venue_description: if(:rand.uniform() < 0.65, do: Faker.Lorem.paragraph(), else: ""),
          locations: [locations |> Enum.random()],
          postal_addresses: [Sportyweb.SeedHelper.get_random_postal_address()],
          emails: [Sportyweb.SeedHelper.get_random_email()],
          phones: [Sportyweb.SeedHelper.get_random_phone()],
          notes: [Sportyweb.SeedHelper.get_random_note()]
        })

      # Fees: Specific - Event

      Repo.insert!(%Fee{
        club_id: club.id,
        is_general: false,
        type: "event",
        name: "Spez. Teilnahmegebühr Veranstaltung #{event.reference_number}",
        reference_number: Sportyweb.SeedHelper.get_random_string(3),
        description: "",
        amount: Money.new(:EUR, Enum.random(10..150)),
        amount_one_time: Money.new(:EUR, 0),
        is_for_contact_group_contacts_only: false,
        minimum_age_in_years: nil,
        maximum_age_in_years: nil,
        internal_events: [Sportyweb.SeedHelper.get_random_internal_event()],
        notes: [%Note{}],
        events: [event]
      })
    end
  end
end)

  #############################################################
  # Add Accounts, Accountclasses, Accountgroups, Accounttypes
  # Da es sich beim Kontenplan um eine gegebene hierarchische handelt, bietet es sich an diese in einer einzigen Datenstruktur abzubilden.
  # Anschließend wird mittels Funktion über diese Datenstruktur iteriert, um nicht für jede Kontenklasse, Kontengruppe, Kontentyp und Konto aus dem SKR42
  # einen einzelnen Repo.insert!-Befehl schreiben zu müssen.
  # Gleichzeitig bietet diese Lösung die Möglichkeit später auch andere Kontenpläne bspw. über eine Datei einzulesen und erzeugen zu lassen.

  # Schritt 1: Die Hierarchie mit Zuordnung zum Typ
  accounting_data = [
    %{
      accountclass: "0", accountclassname: "Anlagevermögen",
      accountgroups: [
        %{
          accountgroupname: "Entgeltlich erworbene Konzessionen, gewerbliche Schutzrechte und ähnliche Rechte und Werte sowie Lizenzen an solchen Rechten und Werten",
          accounttypecode: "aktiv",
            accounts: [
              %{accountnumber: "01000", accountname: "Entgeltlich erworbene Konzessionen, gewerbliche Schutzrechte und ähnliche Rechte und Werte sowie Lizenzen an solchen Rechten und Werten"},
              %{accountnumber: "01100", accountname: "Konzessionen"},
              %{accountnumber: "01200", accountname: "Gewerbliche Schutzrechte"},
              %{accountnumber: "01300", accountname: "Ähnliche Rechte und Werte"},
              %{accountnumber: "01350", accountname: "EDV-Software"},
              %{accountnumber: "01400", accountname: "Lizenzen an gewerblichen Schutzrechten und ähnlichen Rechten und Werten"}
            ]},
        %{
          accountgroupname: "Selbst geschaffene gewerbliche Schutzrechte und ähnliche Rechte und Werte",
          accounttypecode: "aktiv",
            accounts: [
              %{accountnumber: "01430", accountname: "Selbst geschaffene immaterielle Vermögensgegenstände"},
              %{accountnumber: "01440", accountname: "EDV-Software"},
              %{accountnumber: "01450", accountname: "Lizenzen und Franchiseverträge"},
              %{accountnumber: "01460", accountname: "Konzessionen und gewerbliche Schutzrechte"},
              %{accountnumber: "01470", accountname: "Rezepte, Verfahren, Prototypen"}
            ]},
        %{
          accountgroupname: "In der Entwicklung befindliche immaterielle Vermögensgegenstände",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "01480", accountname: "Immaterielle Vermögensgegenstände in Entwicklung"},
            ]},
        %{
          accountgroupname: "Geschäfts- oder Firmenwert",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "01500", accountname: "Geschäfts- oder Firmenwert"},
            ]},
        %{
          accountgroupname: "Geleistete Anzahlungen",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "01700", accountname: "Geleistete Anzahlungen auf immaterielle Vermögensgegenstände"},
              %{accountnumber: "01790", accountname: "Anzahlungen auf Geschäfts- oder Firmenwert"}
            ]},
        %{
          accountgroupname: "Grundstücke, grundstücksgleiche Rechte und Bauten einschließlich der Bauten auf fremden Grundstücken",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "02000", accountname: "Grundstücke, grundstücksgleiche Rechte und Bauten einschließlich der Bauten auf fremden Grundstücken"},
              %{accountnumber: "02100", accountname: "Grundstücksgleiche Rechte ohne Bauten"},
              %{accountnumber: "02150", accountname: "Unbebaute Grundstücke"},
              %{accountnumber: "02200", accountname: "Grundstücksgleiche Rechte (Erbbaurecht, Dauerwohnrecht, unbebaute Grundstücke)"},
              %{accountnumber: "02250", accountname: "Grundstücke mit Substanzverzehr"},
              %{accountnumber: "02300", accountname: "Bauten auf eigenen Grundstücken und grundstücksgleichen Rechten"},
              %{accountnumber: "02350", accountname: "Grundstückswerte eigener bebauter Grundstücke"},
              %{accountnumber: "02400", accountname: "Geschäftsbauten"},
              %{accountnumber: "02410", accountname: "Gebäude"},
              %{accountnumber: "02430", accountname: "Hallen"},
              %{accountnumber: "02440", accountname: "Gaststätte"},
              %{accountnumber: "02500", accountname: "Fabrikbauten"},
              %{accountnumber: "02600", accountname: "Andere Bauten"},
              %{accountnumber: "02700", accountname: "Garagen"},
              %{accountnumber: "02800", accountname: "Außenanlagen"},
              %{accountnumber: "02850", accountname: "Hof- und Wegebefestigungen"},
              %{accountnumber: "02900", accountname: "Einrichtungen für Geschäfts- und andere Bauten"}
            ]},
        %{
          accountgroupname: "Grundstücke, grundstücksgleiche Rechte und Bauten einschließlich der Bauten auf fremden Grundstücken",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "03000", accountname: "Wohnbauten"},
              %{accountnumber: "03050", accountname: "Garagen"},
              %{accountnumber: "03100", accountname: "Außenanlagen"},
              %{accountnumber: "03150", accountname: "Hof- und Wegebefestigungen"},
              %{accountnumber: "03200", accountname: "Einrichtungen für Wohnbauten"},
              %{accountnumber: "03300", accountname: "Bauten auf fremden Grundstücken"},
              %{accountnumber: "03400", accountname: "Geschäftsbauten"},
              %{accountnumber: "03500", accountname: "Fabrikbauten"},
              %{accountnumber: "03600", accountname: "Wohnbauten"},
              %{accountnumber: "03700", accountname: "Andere Bauten"},
              %{accountnumber: "03800", accountname: "Garagen"},
              %{accountnumber: "03900", accountname: "Außenanlagen"},
              %{accountnumber: "03950", accountname: "Hof- und Wegebefestigungen"},
              %{accountnumber: "03980", accountname: "Einrichtungen für Geschäfts-, Wohn- und andere Bauten"}
            ]},
        %{
          accountgroupname: "Technische Anlagen und Maschinen",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "04000", accountname: "Technische Anlagen und Maschinen"},
              %{accountnumber: "04200", accountname: "Technische Anlagen"},
              %{accountnumber: "04400", accountname: "Maschinen"},
              %{accountnumber: "04500", accountname: "Transportanlagen und Ähnliches"},
              %{accountnumber: "04600", accountname: "Maschinengebundene Werkzeuge"},
              %{accountnumber: "04700", accountname: "Betriebsvorrichtungen"},
            ]},
        %{
          accountgroupname: "Andere Anlagen, Betriebsund Geschäftsausstattung",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "05000", accountname: "Andere Anlagen, Betriebs- und Geschäftsausstattung"},
              %{accountnumber: "05100", accountname: "Andere Anlagen"},
              %{accountnumber: "05200", accountname: "Pkw"},
              %{accountnumber: "05250", accountname: "Kraftfahrzeug-Anhänger"},
              %{accountnumber: "05400", accountname: "Lkw"},
              %{accountnumber: "05600", accountname: "Sonstige Transportmittel"},
              %{accountnumber: "05700", accountname: "Pflegemaschinen"}
            ]},
        %{
          accountgroupname: "Andere Anlagen, Betriebsund Geschäftsausstattung",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "06200", accountname: "Werkzeuge"},
              %{accountnumber: "06300", accountname: "Betriebsausstattung"},
              %{accountnumber: "06310", accountname: "Kleidung"},
              %{accountnumber: "06320", accountname: "Geräte"},
              %{accountnumber: "06350", accountname: "Geschäftsausstattung"},
              %{accountnumber: "06400", accountname: "Ladeneinrichtung"},
              %{accountnumber: "06500", accountname: "Büroeinrichtung"},
              %{accountnumber: "06600", accountname: "Gerüst- und Schalungsmaterial"},
              %{accountnumber: "06700", accountname: "Geringwertige Wirtschaftsgüter"},
              %{accountnumber: "06750", accountname: "Wirtschaftsgüter (Sammelposten)"},
              %{accountnumber: "06800", accountname: "Einbauten in fremde Grundstücke"},
              %{accountnumber: "06900", accountname: "Sonstige Betriebs- und Geschäftsausstattung"}
            ]},
        %{
          accountgroupname: "Geleistete Anzahlungen und Anlagen im Bau",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "07000", accountname: "Geleistete Anzahlungen und Anlagen im Bau"},
              %{accountnumber: "07050", accountname: "Anzahlungen auf Grund und Boden"},
              %{accountnumber: "07100", accountname: "Geschäfts-, Fabrik- und andere Bauten im Bau auf eigenen Grundstücken"},
              %{accountnumber: "07200", accountname: "Anzahlungen auf Geschäfts-, Fabrik- und andere Bauten auf eigenen Grundstücken"},
              %{accountnumber: "07250", accountname: "Wohnbauten im Bau auf eigenen Grundstücken"},
              %{accountnumber: "07350", accountname: "Anzahlungen auf Wohnbauten auf eigenen Grundstücken"},
              %{accountnumber: "07400", accountname: "Geschäfts-, Fabrik- und andere Bauten im Bau auf fremden Grundstücken"},
              %{accountnumber: "07500", accountname: "Anzahlungen auf Geschäfts-, Fabrik- und andere Bauten auf fremden Grundstücken"},
              %{accountnumber: "07550", accountname: "Wohnbauten im Bau auf fremden Grundstücken"},
              %{accountnumber: "07650", accountname: "Anzahlungen auf Wohnbauten auf fremden Grundstücken"},
              %{accountnumber: "07700", accountname: "Technische Anlagen und Maschinen im Bau"},
              %{accountnumber: "07800", accountname: "Anzahlungen auf technische Anlagen und Maschinen"},
              %{accountnumber: "07850", accountname: "Andere Anlagen, Betriebs- und Geschäftsausstattung im Bau"},
              %{accountnumber: "07950", accountname: "Anzahlungen auf andere Anlagen, Betriebs- und Geschäftsausstattung"}
            ]},
        %{
          accountgroupname: "Anteile an verbundenen Unternehmen",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "08000", accountname: "Anteile an verbundenen Unternehmen (Anlagevermögen)"},
              %{accountnumber: "08030", accountname: "Anteile an verbundenen Unternehmen, Personengesellschaften"},
              %{accountnumber: "08040", accountname: "Anteile an verbundenen Unternehmen, Kapitalgesellschaften"},
              %{accountnumber: "08050", accountname: "Anteile an herrschender oder mehrheitlich beteiligter Gesellschaft, Personengesellschaften"},
              %{accountnumber: "08080", accountname: "Anteile an herrschender oder mehrheitlich beteiligter Gesellschaft, Kapitalgesellschaften"},
              %{accountnumber: "08090", accountname: "Anteile an herrschender oder mit Mehrheit beteiligter Gesellschaft"}
            ]},
        %{
          accountgroupname: "Ausleihungen an verbundene Unternehmen",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "08100", accountname: "Ausleihungen an verbundene Unternehmen"},
              %{accountnumber: "08130", accountname: "Ausleihungen an verbundene Unternehmen, Personengesellschaften"},
              %{accountnumber: "08140", accountname: "Ausleihungen an verbundene Unternehmen, Kapitalgesellschaften"},
              %{accountnumber: "08150", accountname: "Ausleihungen an verbundene Unternehmen, Einzelunternehmen"}
            ]},
        %{
          accountgroupname: "Beteiligungen",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "08200", accountname: "Beteiligungen"},
              %{accountnumber: "08300", accountname: "Typisch stille Beteiligungen"},
              %{accountnumber: "08400", accountname: "Atypisch stille Beteiligungen"},
              %{accountnumber: "08500", accountname: "Beteiligungen an Kapitalgesellschaften"},
              %{accountnumber: "08600", accountname: "Beteiligungen an Personengesellschaften"}
            ]},
        %{
          accountgroupname: "Ausleihungen an Unternehmen, mit denen ein Beteiligungsverhältnis besteht",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "08800", accountname: "Ausleihungen an Unternehmen, mit denen ein Beteiligungsverhältnis besteht"},
              %{accountnumber: "08830", accountname: "Ausleihungen an Unternehmen, mit denen ein Beteiligungsverhältnis besteht, Personengesellschaften"},
              %{accountnumber: "08850", accountname: "Ausleihungen an Unternehmen, mit denen ein Beteiligungsverhältnis besteht, Kapitalgesellschaften"}
            ]},
        %{
          accountgroupname: "Wertpapiere des Anlagevermögens",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "09000", accountname: "Wertpapiere des Anlagevermögens"},
              %{accountnumber: "09100", accountname: "Wertpapiere mit Gewinnbeteiligungsansprüchen, die dem Teileinkünfteverfahren unterliegen"},
              %{accountnumber: "09200", accountname: "Festverzinsliche Wertpapiere"}
            ]},
        %{
          accountgroupname: "Sonstige Ausleihungen",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "09300", accountname: "Übrige sonstige Ausleihungen"},
              %{accountnumber: "09350", accountname: "Sonstige Ausleihungen - geleistete Kautionen"},
              %{accountnumber: "09400", accountname: "Darlehen"}
            ]},
        %{
          accountgroupname: "Ausleihungen an Gesellschafter",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "09600", accountname: "Ausleihungen an Gesellschafter"},
              %{accountnumber: "09610", accountname: "Ausleihungen an GmbH-Gesellschafter"}
            ]},
        %{
          accountgroupname: "Sonstige Ausleihungen",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "09700", accountname: "Ausleihungen an nahe stehende Personen"}
            ]},
        %{
          accountgroupname: "Genossenschaftsanteile",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "09800", accountname: "Genossenschaftsanteile zum langfristigen Verbleib"}
            ]},
        %{
          accountgroupname: "Rückdeckungsansprüche aus Lebensversicherungen",
          accounttypecode: "aktiv",
          accounts: [
              %{accountnumber: "09900", accountname: "Rückdeckungsansprüche aus Lebensversicherungen zum langfristigen Verbleib"}
            ]},
      ]
     }, %{
      accountclass: "1", accountclassname: "Umlaufvermögen",
       accountgroups: [
         %{
           accountgroupname: "Roh-, Hilfs- und Betriebsstoffe",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "10000", accountname: "Roh-, Hilfs- und Betriebsstoffe (Bestand)"}
             ]},
         %{
           accountgroupname: "Unfertige Erzeugnisse, unfertige Leistungen",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "10400", accountname: "Unfertige Erzeugnisse, unfertige Leistungen (Bestand)"},
               %{accountnumber: "10500", accountname: "Unfertige Erzeugnisse (Bestand)"},
               %{accountnumber: "10800", accountname: "Unfertige Leistungen (Bestand)"}
             ]},
         %{
           accountgroupname: "In Ausführung befindliche Bauaufträge",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "10900", accountname: "In Ausführung befindliche Bauaufträge"}
             ]},
         %{
           accountgroupname: "In Arbeit befindliche Aufträge",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "10950", accountname: "In Arbeit befindliche Aufträge"}
             ]},
         %{
           accountgroupname: "Fertige Erzeugnisse und Waren",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "11000", accountname: "Fertige Erzeugnisse und Waren (Bestand)"},
               %{accountnumber: "11100", accountname: "Fertige Erzeugnisse (Bestand)"},
               %{accountnumber: "11400", accountname: "Waren (Bestand)"},
               %{accountnumber: "11600", accountname: "Waren und Material aus Sachspenden (Bestand)"}
             ]},
         %{
           accountgroupname: "Geleistete Anzahlungen",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "11800", accountname: "Geleistete Anzahlungen auf Vorräte"},
               %{accountnumber: "11810", accountname: "Geleistete Anzahlungen 7 % Vorsteuer"},
               %{accountnumber: "11820", accountname: "Geleistete Anzahlungen 5 % Vorsteuer"},
               %{accountnumber: "11840", accountname: "Geleistete Anzahlungen 16 % Vorsteuer"},
               %{accountnumber: "11860", accountname: "Geleistete Anzahlungen 19 % Vorsteuer"}
             ]},
         %{
           accountgroupname: "Erhaltene Anzahlungen auf Bestellungen (von Vorräten offen abgesetzt)",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "11900", accountname: "Erhaltene Anzahlungen auf Bestellungen (von Vorräten offen abgesetzt)"}
             ]},
         %{
           accountgroupname: "Forderungen aus Lieferungen und Leistungen",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "12000", accountname: "Forderungen aus Lieferungen und Leistungen"},
               %{accountnumber: "12100", accountname: "Forderungen aus Lieferungen und Leistungen ohne Kontokorrent"},
               %{accountnumber: "12210", accountname: "Forderungen aus Lieferungen und Leistungen ohne Kontokorrent - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12250", accountname: "Forderungen aus Lieferungen und Leistungen ohne Kontokorrent - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "12400", accountname: "Zweifelhafte Forderungen"},
               %{accountnumber: "12410", accountname: "Zweifelhafte Forderungen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12420", accountname: "Zweifelhafte Forderungen - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "12460", accountname: "Einzelwertberichtigungen auf Forderungen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12470", accountname: "Einzelwertberichtigungen auf Forderungen - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "12480", accountname: "Pauschalwertberichtigung auf Forderungen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12490", accountname: "Pauschalwertberichtigung auf Forderungen - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "12580", accountname: "Gegenkonto zu sonstigen Vermögensgegenständen bei Buchungen über Debitorenkonto"},
               %{accountnumber: "12590", accountname: "Gegenkonto 12210 - 12299, 12400 - 12459, 12500 - 12579, 12700 - 12759, 12900 - 12979 bei Aufteilung Debitorenkonto"}
             ]},
         %{
           accountgroupname: "Forderungen gegen Gesellschafter",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "12500", accountname: "Forderungen aus Lieferungen und Leistungen gegen Gesellschafter"},
               %{accountnumber: "12510", accountname: "Forderungen aus Lieferungen und Leistungen gegen Gesellschafter - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12520", accountname: "Forderungen aus Lieferungen und Leistungen gegen Gesellschafter - Restlaufzeit größer 1 Jahr"}
             ]},
         %{
           accountgroupname: "Forderungen gegen verbundene Unternehmen",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "12600", accountname: "Forderungen gegen verbundene Unternehmen"},
               %{accountnumber: "12610", accountname: "Forderungen gegen verbundene Unternehmen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12620", accountname: "Forderungen gegen verbundene Unternehmen - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "12700", accountname: "Forderungen aus Lieferungen und Leistungen gegen verbundene Unternehmen"},
               %{accountnumber: "12710", accountname: "Forderungen aus Lieferungen und Leistungen gegen verbundene Unternehmen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12720", accountname: "Forderungen aus Lieferungen und Leistungen gegen verbundene Unternehmen - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "12760", accountname: "Wertberichtigungen auf Forderungen gegen verbundene Unternehmen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12770", accountname: "Wertberichtigungen auf Forderungen gegen verbundene Unternehmen - Restlaufzeit größer 1 Jahr"}
             ]},
         %{
           accountgroupname: "Forderungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "12800", accountname: "Forderungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht"},
               %{accountnumber: "12810", accountname: "Forderungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12820", accountname: "Forderungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "12900", accountname: "Forderungen aus Lieferungen und Leistungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht"},
               %{accountnumber: "12910", accountname: "Forderungen aus Lieferungen und Leistungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12920", accountname: "Forderungen aus Lieferungen und Leistungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "12960", accountname: "Wertberichtigungen auf Forderungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "12970", accountname: "Wertberichtigungen auf Forderungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit größer 1 Jahr"}
             ]},
         %{
           accountgroupname: "Eingeforderte, noch ausstehende Kapitaleinlagen",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "12980", accountname: "Ausstehende Einlagen auf das gezeichnete Kapital, eingefordert (Forderungen, nicht eingeforderte ausstehende Einlagen s. Konto 2910 0)"}
             ]},
         %{
           accountgroupname: "Eingeforderte Nachschüsse",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "12990", accountname: "Nachschüsse (Forderungen, Gegenkonto 2929 0)"}
             ]},
         %{
           accountgroupname: "Sonstige Vermögensgegenstände",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "13000", accountname: "Sonstige Vermögensgegenstände"},
               %{accountnumber: "13010", accountname: "Sonstige Vermögensgegenstände - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13020", accountname: "Sonstige Vermögensgegenstände - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "13100", accountname: "Forderungen gegen Vorstandsmitglieder und Geschäftsführer"},
               %{accountnumber: "13110", accountname: "Forderungen gegen Vorstandsmitglieder und Geschäftsführer - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13120", accountname: "Forderungen gegen Vorstandsmitglieder und Geschäftsführer - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "13200", accountname: "Forderungen gegen Aufsichtsratsund Beiratsmitglieder"},
               %{accountnumber: "13210", accountname: "Forderungen gegen Aufsichtsratsund Beiratsmitglieder - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13220", accountname: "Forderungen gegen Aufsichtsratsund Beiratsmitglieder - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "13370", accountname: "Forderungen gegen typisch stille Gesellschafter"},
               %{accountnumber: "13380", accountname: "Forderungen gegen typisch stille Gesellschafter - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13390", accountname: "Forderungen gegen typisch stille Gesellschafter - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "13400", accountname: "Forderungen gegen Personal aus Lohn- und Gehaltsabrechnung"},
               %{accountnumber: "13410", accountname: "Forderungen gegen Personal aus Lohn- und Gehaltsabrechnung - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13420", accountname: "Forderungen gegen Personal aus Lohn- und Gehaltsabrechnung - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "13500", accountname: "Kautionen"},
               %{accountnumber: "13510", accountname: "Kautionen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13520", accountname: "Kautionen - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "13600", accountname: "Darlehen"},
               %{accountnumber: "13610", accountname: "Darlehen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13620", accountname: "Darlehen - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "13640", accountname: "Forderungen aus entrichteten Verbrauchsteuern"},
               %{accountnumber: "13650", accountname: "Forderungen aus Gewerbesteuerüberzahlungen"},
               %{accountnumber: "13660", accountname: "Körperschaftsteuerrückforderung"},
               %{accountnumber: "13670", accountname: "Forderungen an das Finanzamt aus abgeführtem Bauabzugsbetrag"},
               %{accountnumber: "13680", accountname: "Forderungen gegenüber Bundesagentur für Arbeit"},
               %{accountnumber: "13690", accountname: "Forderungen gegenüber Krankenkassen aus Aufwendungsausgleichsgesetz"},
               %{accountnumber: "13700", accountname: "Durchlaufende Posten"},
               %{accountnumber: "13720", accountname: "Geldtransit"},
               %{accountnumber: "13740", accountname: "Fremdgeld"},
               %{accountnumber: "13750", accountname: "Agenturwarenabrechnung"},
               %{accountnumber: "13780", accountname: "Ansprüche aus Rückdeckungsversicherungen"},
               %{accountnumber: "13800", accountname: "Vermögensgegenstände zur Erfüllung von Pensionsrückstellungen und ähnlichen Verpflichtungen zum langfristigen Verbleib"},
               %{accountnumber: "13820", accountname: "Vermögensgegenstände zur Erfüllung von mit der Altersversorgung vergleichbaren langfristigen Verpflichtungen"},
               %{accountnumber: "13900", accountname: "GmbH-Anteile zum kurzfristigen Verbleib"},
               %{accountnumber: "13910", accountname: "Forderungen gegen Arbeitsgemeinschaften"},
               %{accountnumber: "13930", accountname: "Genussrechte"},
               %{accountnumber: "13940", accountname: "Einzahlungsansprüche zu Nebenleistungen oder Zuzahlungen"},
               %{accountnumber: "13950", accountname: "Genossenschaftsanteile zum kurzfristigen Verbleib"}
             ]},
         %{
           accountgroupname: "Sonstige Vermögensgegenstände",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "14000", accountname: "Abziehbare Vorsteuer"},
               %{accountnumber: "14010", accountname: "Abziehbare Vorsteuer 7 %"},
               %{accountnumber: "14060", accountname: "Abziehbare Vorsteuer 19 %"},
               %{accountnumber: "14100", accountname: "Abziehbare Vorsteuer nach § 13b UStG"},
               %{accountnumber: "14160", accountname: "Abziehbare Vorsteuer nach § 13b UStG 19 %"},
               %{accountnumber: "14200", accountname: "Abziehbare Vorsteuer aus innergemeinschaftlichem Erwerb"},
               %{accountnumber: "14260", accountname: "Abziehbare Vorsteuer aus innergemeinschaftlichem Erwerb 19 %"},
               %{accountnumber: "14290", accountname: "Abziehbare Vorsteuer aus innergemeinschaftlichem Erwerb von Neufahrzeugen von Lieferanten ohne Umsatzsteuer-Identifikationsnummer"},
               %{accountnumber: "14300", accountname: "Aufzuteilende Vorsteuer"},
               %{accountnumber: "14310", accountname: "Aufzuteilende Vorsteuer 7 %"},
               %{accountnumber: "14360", accountname: "Aufzuteilende Vorsteuer 19 %"},
               %{accountnumber: "14400", accountname: "Aufzuteilende Vorsteuer nach §§ 13a und 13b UStG"},
               %{accountnumber: "14460", accountname: "Aufzuteilende Vorsteuer nach §§ 13a und 13b UStG 19 %"},
               %{accountnumber: "14500", accountname: "Aufzuteilende Vorsteuer aus innergemeinschaftlichem Erwerb"},
               %{accountnumber: "14560", accountname: "Aufzuteilende Vorsteuer aus innergemeinschaftlichem Erwerb 19 %"},
               %{accountnumber: "14590", accountname: "Vorsteuer aus Erwerb als letzter Abnehmer innerhalb eines Dreiecksgeschäfts"},
               %{accountnumber: "14610", accountname: "Forderungen aus Umsatzsteuer-Vorauszahlungen"},
               %{accountnumber: "14620", accountname: "Umsatzsteuerforderungen Vorjahr"},
               %{accountnumber: "14630", accountname: "Umsatzsteuerforderungen frühere Jahre"},
               %{accountnumber: "14640", accountname: "Nachträglich abziehbare Vorsteuer nach § 15a Abs. 2 UStG"},
               %{accountnumber: "14690", accountname: "Steuererstattungsansprüche gegenüber anderen Ländern"},
               %{accountnumber: "14700", accountname: "Nachträglich abziehbare Vorsteuer nach § 15a Abs. 1 UStG, bewegliche Wirtschaftsgüter"},
               %{accountnumber: "14710", accountname: "Nachträglich abziehbare Vorsteuer nach § 15a Abs. 1 UStG, unbewegliche Wirtschaftsgüter"},
               %{accountnumber: "14720", accountname: "Zurückzuzahlende Vorsteuer nach § 15a Abs. 1 UStG, bewegliche Wirtschaftsgüter"},
               %{accountnumber: "14730", accountname: "Zurückzuzahlende Vorsteuer nach § 15a Abs. 1 UStG, unbewegliche Wirtschaftsgüter"},
               %{accountnumber: "14740", accountname: "Zurückzuzahlende Vorsteuer nach § 15a Abs. 2 UStG"},
               %{accountnumber: "14800", accountname: "Abziehbare Vorsteuer aus der Auslagerung von Gegenständen aus einem Umsatzsteuerlager"},
               %{accountnumber: "14810", accountname: "Entstandene Einfuhrumsatzsteuer"},
               %{accountnumber: "14820", accountname: "Vorsteuer in Folgeperiode / im Folgejahr abziehbar"},
               %{accountnumber: "14870", accountname: "Vorsteuer nach allgemeinen Durchschnittssätzen"},
               %{accountnumber: "14950", accountname: "Verrechnungskonto Ist-Versteuerung"},
               %{accountnumber: "14970", accountname: "Verrechnungskonto erhaltene Anzahlungen bei Buchung über Debitorenkonto"},
               %{accountnumber: "14980", accountname: "Überleitungskonto Kostenstellen"}
             ]},
         %{
           accountgroupname: "Forderungen gegen Gesellschafter",
           accounttypecode: "aktiv",
           accounts: [
               %{accountnumber: "13070", accountname: "Forderungen gegen GmbH-Gesellschafter"},
               %{accountnumber: "13080", accountname: "Forderungen gegen GmbH-Gesellschafter - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13090", accountname: "Forderungen gegen GmbH-Gesellschafter - Restlaufzeit größer 1 Jahr"},
               %{accountnumber: "13300", accountname: "Forderungen gegen sonstige Gesellschafter"},
               %{accountnumber: "13310", accountname: "Forderungen gegen sonstige Gesellschafter - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "13320", accountname: "Forderungen gegen sonstige Gesellschafter - Restlaufzeit größer 1 Jahr"}
             ]},
         %{
           accountgroupname: "Aktiver Unterschiedsbetrag aus der Vermögensverrechnung",
           accounttypecode: "aktiv",
          accounts: [
               %{accountnumber: "13810", accountname: "Vermögensgegenstände zur Saldierung mit Pensionsrückstellungen und ähnlichen Verpflichtungen zum langfristigen Verbleib nach § 246 Abs. 2 HGB"},
               %{accountnumber: "13830", accountname: "Vermögensgegenstände zur Saldierung mit der Altersversorgung vergleichbaren langfristigen Verpflichtungen nach § 246 Abs. 2 HGB"}
             ]},
         %{
           accountgroupname: "Anteile an verbundenen Unternehmen",
           accounttypecode: "aktiv",
          accounts: [
               %{accountnumber: "15000", accountname: "Anteile an verbundenen Unternehmen (Umlaufvermögen)"},
               %{accountnumber: "15040", accountname: "Anteile an herrschender oder mit Mehrheit beteiligter Gesellschaft"}
             ]},
         %{
           accountgroupname: "Sonstige Wertpapiere",
           accounttypecode: "aktiv",
          accounts: [
               %{accountnumber: "15100", accountname: "Sonstige Wertpapiere"},
               %{accountnumber: "15250", accountname: "Andere Wertpapiere mit unwesentlichen Wertschwankungen"},
               %{accountnumber: "15300", accountname: "Wertpapieranlagen im Rahmen der kurzfristigen Finanzdisposition"}
             ]},
         %{
           accountgroupname: "Kassenbestand, Bundesbankguthaben, Guthaben bei Kreditinstituten und Schecks",
           accounttypecode: "aktiv",
          accounts: [
               %{accountnumber: "15500", accountname: "Schecks"},
               %{accountnumber: "16000", accountname: "Kasse"},
               %{accountnumber: "16100", accountname: "Nebenkasse 1"},
               %{accountnumber: "16200", accountname: "Nebenkasse 2"},
               %{accountnumber: "17000", accountname: "Bank (Postbank)"},
               %{accountnumber: "17100", accountname: "Bank (Postbank 1)"},
               %{accountnumber: "17200", accountname: "Bank (Postbank 2)"},
               %{accountnumber: "17300", accountname: "Bank (Postbank 3)"},
               %{accountnumber: "17800", accountname: "LZB-Guthaben"},
               %{accountnumber: "17900", accountname: "Bundesbankguthaben"},
               %{accountnumber: "18000", accountname: "Bank"},
               %{accountnumber: "18100", accountname: "Bank 1"},
               %{accountnumber: "18200", accountname: "Bank 2"},
               %{accountnumber: "18300", accountname: "Bank 3"},
               %{accountnumber: "18400", accountname: "Bank 4"},
               %{accountnumber: "18500", accountname: "Bank 5"},
               %{accountnumber: "18900", accountname: "Finanzmittelanlagen im Rahmen der kurzfristigen Finanzdisposition (nicht im Finanzmittelfonds enthalten)"}
             ]},
         %{
           accountgroupname: "Verbindlichkeiten gegenüber Kreditinstituten",
           accounttypecode: "aktiv",
          accounts: [
               %{accountnumber: "18950", accountname: "Verbindlichkeiten gegenüber Kreditinstituten (nicht im Finanzmittelfonds enthalten)"}
             ]},
         %{
           accountgroupname: "Rechnungsabgrenzungsposten",
           accounttypecode: "aktiv",
          accounts: [
               %{accountnumber: "19000", accountname: "Aktive Rechnungsabgrenzung"},
               %{accountnumber: "19200", accountname: "Als Aufwand berücksichtigte Zölle und Verbrauchsteuern auf Vorräte"},
               %{accountnumber: "19300", accountname: "Als Aufwand berücksichtigte Umsatzsteuer auf Anzahlungen"},
               %{accountnumber: "19400", accountname: "Damnum / Disagio"}
             ]},
         %{
           accountgroupname: "Aktive latente Steuern",
           accounttypecode: "aktiv",
          accounts: [
               %{accountnumber: "19500", accountname: "Aktive latente Steuern"}
             ]}
       ]
     }, %{
       accountclass: "2", accountclassname: "Eigenkapital",
       accountgroups: [
         %{
           accountgroupname: "Gebundene Rücklage (Vereine/Stiftungen) / andere Gewinnrücklagen (gGmbH)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "20000", accountname: "Gebundene Rücklagen nach § 62 Abs. 1 Nr. 1 AO"},
               %{accountnumber: "20800", accountname: "Wiederbeschaffungsrücklage"},
               %{accountnumber: "20900", accountname: "Betriebsmittelrücklage"}
             ]},
         %{
           accountgroupname: "Freie Rücklage (Vereine/Stiftungen) / andere Gewinnrücklagen (gGmbH)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "21000", accountname: "Freie Rücklagen nach § 62 Abs. 1 Nr. 3 AO"},
               %{accountnumber: "22000", accountname: "Rücklage aus sonstigen zeitnah zu verwendenden Mitteln"},
               %{accountnumber: "22500", accountname: "Rücklagen zum Erwerb von Gesellschaftsrechten nach § 62 Abs. 1 Nr. 4 AO"}
             ]},
         %{
           accountgroupname: "Nutzungsgebundenes Kapital",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "23000", accountname: "Nutzungsgebundenes Kapital (Eigenkapitalausweis)"}
             ]},
         %{
           accountgroupname: "Ergebnisse Vermögensumschichtungen (Vereine/Stiftungen) / andere Gewinnrücklagen (gGmbH)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "24000", accountname: "Ergebnisse Vermögensumschichtung"}
             ]},
         %{
           accountgroupname: "Vereinskapital / sonstige nicht zeitnah zu verwendende Mittel (Stiftungen) / Kapitalrücklage (gGmbH)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "25000", accountname: "Vereinskapital / sonstige nicht zeitnah zu verwendende Mittel nach § 62 Abs. 3 AO"}
             ]},
         %{
           accountgroupname: "Errichtungskapital",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "26000", accountname: "Errichtungskapital"}
             ]},
         %{
           accountgroupname: "Zustiftungskapital",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "26500", accountname: "Zustiftungskapital"}
             ]},
         %{
           accountgroupname: "Zuführung aus Ergebnisrücklagen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "27000", accountname: "Zuführung aus Ergebnisrücklagen"}
             ]},
         %{
           accountgroupname: "Verbrauchskapital",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "27100", accountname: "Verbrauchskapital"}
             ]},
         %{
           accountgroupname: "Kapitalerhaltungsrücklage",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "27500", accountname: "Kapitalerhaltungsrücklage"}
             ]},
         %{
           accountgroupname: "Ansparrücklage",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "28000", accountname: "Ansparrücklage nach § 62 Abs. 4 AO"}
             ]},
         %{
           accountgroupname: "Sonstige Ergebnisrücklagen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "28500", accountname: "Sonstige Ergebnisrücklagen"}
             ]},
         %{
           accountgroupname: "Gezeichnetes Kapital",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29000", accountname: "Gezeichnetes Kapital"},
               %{accountnumber: "29080", accountname: "Kapitalerhöhung aus Gesellschaftsmitteln"}
             ]},
         %{
           accountgroupname: "Eigene Anteile",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29090", accountname: "Erworbene eigene Anteile"}
             ]},
         %{
           accountgroupname: "Nicht eingeforderte ausstehende Einlagen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29100", accountname: "Ausstehende Einlagen auf das gezeichnete Kapital, nicht eingefordert (Passivausweis, vom gezeichneten Kapital offen abgesetzt; eingeforderte ausstehende Einlagen s. Konto 1298 0)"}
             ]},
         %{
           accountgroupname: "Kapitalrücklage",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29200", accountname: "Kapitalrücklage"},
               %{accountnumber: "29250", accountname: "Kapitalrücklage durch Ausgabe von Anteilen über Nennbetrag"},
               %{accountnumber: "29260", accountname: "Kapitalrücklage durch Ausgabe von Schuldverschreibungen für Wandlungsrechte und Optionsrechte zum Erwerb von Anteilen"},
               %{accountnumber: "29270", accountname: "Kapitalrücklage durch Zuzahlungen gegen Gewährung eines Vorzugs für Anteile"},
               %{accountnumber: "29280", accountname: "Kapitalrücklage durch Zuzahlungen in das Eigenkapital"},
               %{accountnumber: "29290", accountname: "Nachschusskapital (Gegenkonto 12990)"}
             ]},
         %{
           accountgroupname: "Gesetzliche Rücklage",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29300", accountname: "Gesetzliche Rücklage"}
             ]},
         %{
           accountgroupname: "Rücklage für Anteile an einem herrschenden oder mehrheitlich beteiligten Unternehmen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29350", accountname: "Rücklage für Anteile an einem herrschenden oder mehrheitlich beteiligten Unternehmen"}
             ]},
         %{
           accountgroupname: "Satzungsmäßige Rücklagen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29500", accountname: "Satzungsmäßige Rücklagen"}
             ]},
         %{
           accountgroupname: "Andere Gewinnrücklagen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29600", accountname: "Andere Gewinnrücklagen"},
               %{accountnumber: "29610", accountname: "Andere Gewinnrücklagen aus dem Erwerb eigener Anteile"},
               %{accountnumber: "29620", accountname: "Eigenkapitalanteil von Wertaufholungen"},
               %{accountnumber: "29630", accountname: "Gewinnrücklagen aus den Übergangsvorschriften BilMoG"},
               %{accountnumber: "29640", accountname: "Gewinnrücklagen aus den Übergangsvorschriften BilMoG (Zuschreibung Sachanlagevermögen)"},
               %{accountnumber: "29650", accountname: "Gewinnrücklagen aus den Übergangsvorschriften BilMoG (Zuschreibung Finanzanlagevermögen)"},
               %{accountnumber: "29660", accountname: "Gewinnrücklagen aus den Übergangsvorschriften BilMoG (Auflösung der Sonderposten mit Rücklageanteil)"},
               %{accountnumber: "29670", accountname: "Latente Steuern (Gewinnrücklage Haben) aus erfolgsneutralen Verrechnungen"},
               %{accountnumber: "29680", accountname: "Latente Steuern (Gewinnrücklage Soll) aus erfolgsneutralen Verrechnungen"},
               %{accountnumber: "29690", accountname: "Rechnungsabgrenzungsposten (Gewinnrücklage Soll) aus erfolgsneutralen Verrechnungen"}
             ]},
         %{
           accountgroupname: "Ergebnisvortrag (Vereine/Stiftungen) / Gewinnvortrag (gGmbH)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29700", accountname: "Gewinnvortrag / Ergebnisvortrag vor Verwendung"},
               %{accountnumber: "29780", accountname: "Verlustvortrag / Ergebnisvortrag vor Verwendung"}
             ]},
         %{
           accountgroupname: "Genussrechtskapital mit Eigenkapital-Charakter",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29790", accountname: "Genussrechtskapital mit Eigenkapitalcharakter"}
             ]},
         %{
           accountgroupname: "Andere Sonderposten",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29800", accountname: "Übrige andere Sonderposten"},
               %{accountnumber: "29810", accountname: "Steuerfreie Rücklagen nach § 6b EStG"},
               %{accountnumber: "29820", accountname: "Rücklage für Ersatzbeschaffung"},
               %{accountnumber: "29830", accountname: "Rücklage für Zuschüsse"},
               %{accountnumber: "29850", accountname: "Ausgleichsposten bei Entnahmen § 4g EStG"}
             ]},
         %{
           accountgroupname: "Sonderposten mit Rücklageanteil",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29840", accountname: "Sonderposten mit Rücklageanteil, Sonderabschreibungen"},
               %{accountnumber: "29860", accountname: "Sonderposten mit Rücklageanteil nach § 7g Abs. 5 EStG"}
             ]},
         %{
           accountgroupname: "Sonderposten für Investitionszulagen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29870", accountname: "Sonderposten für Investitionszulagen"},
               %{accountnumber: "29880", accountname: "Sonderposten für Zuschüsse Dritter"}
             ]},
         %{
           accountgroupname: "Nutzungsgebundenes Kapital",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29950", accountname: "Nutzungsgebundenes Kapital"}
             ]},
         %{
           accountgroupname: "Längerfristig gebundene Spenden",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29960", accountname: "Längerfristig gebundene Spenden"}
             ]},
         %{
           accountgroupname: "Noch nicht satzungsgemäß verwendete Spenden",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "29970", accountname: "Noch nicht satzungsgemäß verwendete Spenden"}
             ]}
       ]
     }, %{
       accountclass: "3", accountclassname: "Fremdkapital",
       accountgroups: [
         %{
           accountgroupname: "Rückstellungen für Pensionen und ähnliche Verpflichtungen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "30000", accountname: "Rückstellungen für Pensionen und ähnliche Verpflichtungen"},
               %{accountnumber: "30050", accountname: "Rückstellungen für Pensionen und ähnliche Verpflichtungen gegenüber Gesellschaftern oder nahe stehenden Personen"},
               %{accountnumber: "30100", accountname: "Rückstellungen für Direktzusagen"},
               %{accountnumber: "30110", accountname: "Rückstellungen für Zuschussverpflichtungen für Pensionskassen und Lebensversicherungen"},
               %{accountnumber: "30150", accountname: "Rückstellungen für pensionsähnliche Verpflichtungen"}
             ]},
         %{
           accountgroupname: "Rückstellungen für Pensionen und ähnliche Verpflichtungen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "30090", accountname: "Rückstellungen für Pensionen und ähnliche Verpflichtungen zur Saldierung mit Vermögensgegenständen zum langfristigen Verbleib nach § 246 Abs. 2 HGB"}
             ]},
         %{
           accountgroupname: "Steuerrückstellungen (allgemein)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "30200", accountname: "Steuerrückstellungen"},
               %{accountnumber: "30350", accountname: "Gewerbesteuerrückstellung nach § 4 Abs. 5b EStG"},
               %{accountnumber: "30400", accountname: "Körperschaftsteuerrückstellung"},
               %{accountnumber: "30500", accountname: "Steuerrückstellung für Steuerstundung (BStBK)"}
             ]},
         %{
           accountgroupname: "Rückstellungen für latente Steuern",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "30600", accountname: "Rückstellungen für latente Steuern"}
             ]},
         %{
           accountgroupname: "Passive latente Steuern",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "30650", accountname: "Passive latente Steuern"}
             ]},
         %{
           accountgroupname: "Sonstige Rückstellungen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "30700", accountname: "Sonstige Rückstellungen"},
               %{accountnumber: "30740", accountname: "Rückstellungen für Personalkosten"},
               %{accountnumber: "30750", accountname: "Rückstellungen für unterlassene Aufwendungen für Instandhaltung, Nachholung in den ersten drei Monaten"},
               %{accountnumber: "30760", accountname: "Rückstellungen für mit der Altersversorgung vergleichbare langfristige Verpflichtungen zum langfristigen Verbleib"},
               %{accountnumber: "30770", accountname: "Rückstellungen für mit der Altersversorgung vergleichbare langfristige Verpflichtungen zur Saldierung mit Vermögensgegenständen zum langfristigen Verbleib nach § 246 Abs. 2 HGB"},
               %{accountnumber: "30790", accountname: "Urlaubsrückstellungen"},
               %{accountnumber: "30850", accountname: "Rückstellungen für Abraum- und Abfallbeseitigung"},
               %{accountnumber: "30900", accountname: "Rückstellungen für Gewährleistungen (Gegenkonto 6790 0)"},
               %{accountnumber: "30920", accountname: "Rückstellungen für drohende Verluste aus schwebenden Geschäften"},
               %{accountnumber: "30950", accountname: "Rückstellungen für Abschluss- und Prüfungskosten"},
               %{accountnumber: "30960", accountname: "Rückstellungen zur Erfüllung der Aufbewahrungspflichten"},
               %{accountnumber: "30980", accountname: "Aufwandsrückstellungen nach § 249 Abs. 2 HGB a. F."},
               %{accountnumber: "30990", accountname: "Rückstellungen für Umweltschutz"}
             ]},
         %{
           accountgroupname: "Anleihen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "31000", accountname: "Anleihen, nicht konvertibel"},
               %{accountnumber: "31010", accountname: "Anleihen, nicht konvertibel - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "31020", accountname: "Anleihen, nicht konvertibel - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "31030", accountname: "Anleihen, nicht konvertibel - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "31200", accountname: "Anleihen, konvertibel"},
               %{accountnumber: "31210", accountname: "Anleihen, konvertibel - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "31220", accountname: "Anleihen, konvertibel - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "31230", accountname: "Anleihen, konvertibel - Restlaufzeit größer 5 Jahre"}
             ]},
         %{
           accountgroupname: "Sonstige Schuld- und Finanztitel",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "31400", accountname: "Sonstige Schuld- und Finanztitel"},
               %{accountnumber: "31410", accountname: "Bewilligungen"},
               %{accountnumber: "31420", accountname: "Rückgängig gemachte Bewilligungen"}
             ]},
         %{
           accountgroupname: "Verbindlichkeiten gegenüber Kreditinstituten",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "31500", accountname: "Verbindlichkeiten gegenüber Kreditinstituten"},
               %{accountnumber: "31510", accountname: "Verbindlichkeiten gegenüber Kreditinstituten - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "31520", accountname: "Verbindlichkeiten gegenüber Kreditinstituten - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "31530", accountname: "Verbindlichkeiten gegenüber Kreditinstituten - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "31800", accountname: "Verbindlichkeiten gegenüber Kreditinstituten aus Teilzahlungsverträgen"},
               %{accountnumber: "31810", accountname: "Verbindlichkeiten gegenüber Kreditinstituten aus Teilzahlungsverträgen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "31820", accountname: "Verbindlichkeiten gegenüber Kreditinstituten aus Teilzahlungsverträgen - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "31830", accountname: "Verbindlichkeiten gegenüber Kreditinstituten aus Teilzahlungsverträgen - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "32100", accountname: "Verbindlichkeiten gegenüber Kreditinstituten, vor Restlaufzeitdifferenzierung"},
               %{accountnumber: "32490", accountname: "Gegenkonto 3150 0 - 3183 9 bei Aufteilung der Konten 3210 0 - 3248 9"}
             ]},
         %{
           accountgroupname: "Erhaltene Anzahlungen auf Bestellungen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "32500", accountname: "Erhaltene Anzahlungen auf Bestellungen (Verbindlichkeiten)"},
               %{accountnumber: "32600", accountname: "Erhaltene, versteuerte Anzahlungen 7 % USt (Verbindlichkeiten)"},
               %{accountnumber: "32610", accountname: "Erhaltene, versteuerte Anzahlungen 5 % USt (Verbindlichkeiten)"},
               %{accountnumber: "32640", accountname: "Erhaltene, versteuerte Anzahlungen 0 % USt (Verbindlichkeiten)"},
               %{accountnumber: "32700", accountname: "Erhaltene, versteuerte Anzahlungen 16 % USt (Verbindlichkeiten)"},
               %{accountnumber: "32720", accountname: "Erhaltene, versteuerte Anzahlungen 19 % USt (Verbindlichkeiten)"},
               %{accountnumber: "32800", accountname: "Erhaltene Anzahlungen - Nachsteuer"},
               %{accountnumber: "32810", accountname: "Erhaltene Anzahlungen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "32820", accountname: "Erhaltene Anzahlungen - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "32830", accountname: "Erhaltene Anzahlungen - Restlaufzeit größer 5 Jahre"}
             ]},
         %{
           accountgroupname: "Verbindlichkeiten aus Lieferungen und Leistungen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "33000", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen"},
               %{accountnumber: "33100", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen ohne Kontokorrent"},
               %{accountnumber: "33310", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen ohne Kontokorrent - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "33320", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen ohne Kontokorrent - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "33330", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen ohne Kontokorrent - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "33400", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber Gesellschaftern"},
               %{accountnumber: "33410", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber Gesellschaftern - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "33420", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber Gesellschaftern - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "33430", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber Gesellschaftern - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "33490", accountname: "Gegenkonto 3331 0 - 333 9, 3340 0 - 3343 9, 3420 0 - 3423 9, 3470 0 - 3473 9 bei Aufteilung Kreditorenkonto"}
             ]},
         %{
           accountgroupname: "Verbindlichkeiten gegenüber verbundenen Unternehmen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "34000", accountname: "Verbindlichkeiten gegenüber verbundenen Unternehmen"},
               %{accountnumber: "34010", accountname: "Verbindlichkeiten gegenüber verbundenen Unternehmen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "34020", accountname: "Verbindlichkeiten gegenüber verbundenen Unternehmen - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "34030", accountname: "Verbindlichkeiten gegenüber verbundenen Unternehmen - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "34200", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber verbundenen Unternehmen"},
               %{accountnumber: "34210", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber verbundenen Unternehmen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "34220", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber verbundenen Unternehmen - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "34230", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber verbundenen Unternehmen - Restlaufzeit größer 5 Jahre"}
             ]},
         %{
           accountgroupname: "Verbindlichkeiten gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "34500", accountname: "Verbindlichkeiten gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht"},
               %{accountnumber: "34510", accountname: "Verbindlichkeiten gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "34520", accountname: "Verbindlichkeiten gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "34530", accountname: "Verbindlichkeiten gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "34700", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht"},
               %{accountnumber: "34710", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "34720", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "34730", accountname: "Verbindlichkeiten aus Lieferungen und Leistungen gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht - Restlaufzeit größer 5 Jahre"}
             ]},
         %{
           accountgroupname: "Sonstige Verbindlichkeiten",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "34900", accountname: "Verbindlichkeiten für satzungsgemäße Leistungen"},
               %{accountnumber: "34910", accountname: "Verbindlichkeiten aus erteilten Zusagen"},
               %{accountnumber: "34920", accountname: "Verbindlichkeiten aus nicht zweckentsprechend verwendeten Mitteln"},
               %{accountnumber: "34930", accountname: "Verbindlichkeiten aus bedingt rückzahlungspflichtigen Spenden"},
               %{accountnumber: "35000", accountname: "Sonstige Verbindlichkeiten"},
               %{accountnumber: "35010", accountname: "Sonstige Verbindlichkeiten - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "35020", accountname: "Sonstige Verbindlichkeiten - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "35030", accountname: "Sonstige Verbindlichkeiten - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "35200", accountname: "Verbindlichkeiten gegenüber typisch stillen Gesellschaftern"},
               %{accountnumber: "35210", accountname: "Verbindlichkeiten gegenüber typisch stillen Gesellschaftern - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "35220", accountname: "Verbindlichkeiten gegenüber typisch stillen Gesellschaftern - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "35230", accountname: "Verbindlichkeiten gegenüber typisch stillen Gesellschaftern - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "35300", accountname: "Verbindlichkeiten gegenüber atypisch stillen Gesellschaftern"},
               %{accountnumber: "35310", accountname: "Verbindlichkeiten gegenüber atypisch stillen Gesellschaftern - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "35320", accountname: "Verbindlichkeiten gegenüber atypisch stillen Gesellschaftern - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "35330", accountname: "Verbindlichkeiten gegenüber atypisch stillen Gesellschaftern - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "35400", accountname: "Partiarische Darlehen"},
               %{accountnumber: "35410", accountname: "Partiarische Darlehen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "35420", accountname: "Partiarische Darlehen - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "35430", accountname: "Partiarische Darlehen - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "35500", accountname: "Erhaltene Kautionen"},
               %{accountnumber: "35510", accountname: "Erhaltene Kautionen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "35520", accountname: "Erhaltene Kautionen - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "35530", accountname: "Erhaltene Kautionen - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "35600", accountname: "Darlehen"},
               %{accountnumber: "35610", accountname: "Darlehen - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "35620", accountname: "Darlehen - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "35630", accountname: "Darlehen - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "35700", accountname: "Sonstige Verbindlichkeiten, vor Restlaufzeitdifferenzierung (nur Bilanzierer)"},
               %{accountnumber: "35990", accountname: "Gegenkonto 3500 0 - 3569 9 und 3640 0 - 36539 9 bei Aufteilung der Konten 3570 0 - 3598 9"},
               %{accountnumber: "36000", accountname: "Agenturwarenabrechnung"},
               %{accountnumber: "36100", accountname: "Kreditkartenabrechnung"},
               %{accountnumber: "36110", accountname: "Verbindlichkeiten gegenüber Arbeitsgemeinschaften"},
               %{accountnumber: "36200", accountname: "Gewinnverfügungskonto stille Gesellschafter - sonstige Verbindlichkeiten"},
               %{accountnumber: "36300", accountname: "Sonstige Verrechnungskonten (Interimskonto)"},
               %{accountnumber: "36500", accountname: "Verbindlichkeiten gegenüber stillen Gesellschaftern"},
               %{accountnumber: "36510", accountname: "Verbindlichkeiten gegenüber stillen Gesellschaftern - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "36520", accountname: "Verbindlichkeiten gegenüber stillen Gesellschaftern - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "36530", accountname: "Verbindlichkeiten gegenüber stillen Gesellschaftern - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "37000", accountname: "Verbindlichkeiten aus Steuern und Abgaben"},
               %{accountnumber: "37010", accountname: "Verbindlichkeiten aus Steuern und Abgaben - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "37020", accountname: "Verbindlichkeiten aus Steuern und Abgaben - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "37030", accountname: "Verbindlichkeiten aus Steuern und Abgaben - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "37200", accountname: "Verbindlichkeiten aus Lohn und Gehalt"},
               %{accountnumber: "37250", accountname: "Verbindlichkeiten für Einbehaltungen von Arbeitnehmern"},
               %{accountnumber: "37260", accountname: "Verbindlichkeiten an das Finanzamt aus abzuführendem Bauabzugsbetrag"},
               %{accountnumber: "37300", accountname: "Verbindlichkeiten aus Lohn- und Kirchensteuer"},
               %{accountnumber: "37400", accountname: "Verbindlichkeiten im Rahmen der sozialen Sicherheit"},
               %{accountnumber: "37410", accountname: "Verbindlichkeiten im Rahmen der sozialen Sicherheit - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "37420", accountname: "Verbindlichkeiten im Rahmen der sozialen Sicherheit - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "37430", accountname: "Verbindlichkeiten im Rahmen der sozialen Sicherheit - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "37590", accountname: "Voraussichtliche Beitragsschuld gegenüber den Sozialversicherungsträgern"},
               %{accountnumber: "37600", accountname: "Verbindlichkeiten aus Einbehaltungen (KapESt und SolZ, KiSt auf KapESt) für offene Ausschüttungen"},
               %{accountnumber: "37610", accountname: "Verbindlichkeiten für Verbrauchsteuern"},
               %{accountnumber: "37700", accountname: "Verbindlichkeiten aus Vermögensbildung"},
               %{accountnumber: "37710", accountname: "Verbindlichkeiten aus Vermögensbildung - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "37720", accountname: "Verbindlichkeiten aus Vermögensbildung - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "37730", accountname: "Verbindlichkeiten aus Vermögensbildung - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "37860", accountname: "Ausgegebene Geschenkgutscheine"},
               %{accountnumber: "37900", accountname: "Lohn- und Gehaltsverrechnungskonto"},
               %{accountnumber: "38000", accountname: "Umsatzsteuer"},
               %{accountnumber: "38010", accountname: "Umsatzsteuer 7 %"},
               %{accountnumber: "38060", accountname: "Umsatzsteuer 19 %"},
               %{accountnumber: "38100", accountname: "Umsatzsteuer nach § 13b UStG"},
               %{accountnumber: "38160", accountname: "Umsatzsteuer nach § 13b UStG 19 %"},
               %{accountnumber: "38400", accountname: "Umsatzsteuer-Vorauszahlungen"},
               %{accountnumber: "38410", accountname: "Umsatzsteuer-Vorauszahlungen"},
               %{accountnumber: "38420", accountname: "Umsatzsteuer laufendes Jahr"},
               %{accountnumber: "38430", accountname: "Umsatzsteuerverbindlichkeiten Vorjahr"},
               %{accountnumber: "38440", accountname: "Umsatzsteuerverbindlichkeiten frühere Jahre"},
               %{accountnumber: "38450", accountname: "Umsatzsteuer in Folgeperiode fällig (§§ 13 Abs. 1 Nr. 6 und 13b Abs. 2 UStG)"},
               %{accountnumber: "38500", accountname: "Umsatzsteuer aus innergemeinschaftlichem Erwerb"},
               %{accountnumber: "38510", accountname: "Umsatzsteuer aus innergemeinschaftlichem Erwerb ohne Vorsteuerabzug"},
               %{accountnumber: "38560", accountname: "Umsatzsteuer aus innergemeinschaftlichem Erwerb 19 %"},
               %{accountnumber: "38570", accountname: "Umsatzsteuer aus Erwerb als letzter Abnehmer innerhalb eines Dreiecksgeschäfts"},
               %{accountnumber: "38580", accountname: "Umsatzsteuer aus innergemeinschaftlichem Erwerb von Neufahrzeugen von Lieferanten ohne Umsatzsteuer-Identifikationsnummer"},
               %{accountnumber: "38600", accountname: "Umsatzsteuer aus der Auslagerung von Gegenständen aus einem Umsatzsteuerlager"},
               %{accountnumber: "38610", accountname: "Umsatzsteuer aus im Inland steuerpflichtigen EU-Lieferungen"},
               %{accountnumber: "38660", accountname: "Umsatzsteuer aus im Inland steuerpflichtigen EU-Lieferungen 19 %"},
               %{accountnumber: "38700", accountname: "Nachsteuer, UStVA Kz. 65"},
               %{accountnumber: "38710", accountname: "Einfuhrumsatzsteuer aufgeschoben bis..."},
               %{accountnumber: "38720", accountname: "In Rechnung unrichtig oder unberechtigt ausgewiesene Steuerbeträge, UStVA Kz. 69"},
               %{accountnumber: "38800", accountname: "Umsatzsteuer aus im anderen EU-Land steuerpflichtigen Lieferungen"},
               %{accountnumber: "38810", accountname: "Umsatzsteuer aus im anderen EU-Land steuerpflichtigen sonstigen Leistungen/Werklieferungen"},
               %{accountnumber: "38820", accountname: "Umsatzsteuer aus im anderen EU-Land steuerpflichtigen elektronischen Dienstleistungen"},
               %{accountnumber: "38830", accountname: "Steuerzahlungen an andere Länder"},
               %{accountnumber: "38840", accountname: "Steuerzahlungen aus im anderen EU-Land steuerpflichtigen Leistungen"},
               %{accountnumber: "38850", accountname: "Umsatzsteuer aus im Inland steuerpflichtigen EU-Lieferungen, nur OSS"},
               %{accountnumber: "38990", accountname: "Verbindlichkeiten aus Umsatzsteuer-Vorauszahlungen"}
             ]},
         %{
           accountgroupname: "Verbindlichkeiten gegenüber Gesellschaftern",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "35100", accountname: "Verbindlichkeiten gegenüber Gesellschaftern"},
               %{accountnumber: "35110", accountname: "Verbindlichkeiten gegenüber Gesellschaftern - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "35120", accountname: "Verbindlichkeiten gegenüber Gesellschaftern - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "35130", accountname: "Verbindlichkeiten gegenüber Gesellschaftern - Restlaufzeit größer 5 Jahre"},
               %{accountnumber: "35190", accountname: "Verbindlichkeiten gegenüber Gesellschaftern für offene Ausschüttungen"},
               %{accountnumber: "36400", accountname: "Verbindlichkeiten gegenüber GmbH-Gesellschaftern"},
               %{accountnumber: "36410", accountname: "Verbindlichkeiten gegenüber GmbH-Gesellschaftern - Restlaufzeit bis 1 Jahr"},
               %{accountnumber: "36420", accountname: "Verbindlichkeiten gegenüber GmbH-Gesellschaftern - Restlaufzeit 1 bis 5 Jahre"},
               %{accountnumber: "36430", accountname: "Verbindlichkeiten gegenüber GmbH-Gesellschaftern - Restlaufzeit größer 5 Jahre"},
             ]},
         %{
           accountgroupname: "Sonstige Vermögensgegenstände",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "36950", accountname: "Verrechnungskonto geleistete Anzahlungen bei Buchung über Kreditorenkonto"}
             ]},
         %{
           accountgroupname: "Steuerrückstellungen (allgemein)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "38200", accountname: "Umsatzsteuer nicht fällig"},
               %{accountnumber: "38210", accountname: "Umsatzsteuer nicht fällig 7 %"},
               %{accountnumber: "38260", accountname: "Umsatzsteuer nicht fällig 19 %"},
               %{accountnumber: "38300", accountname: "Umsatzsteuer nicht fällig aus im Inland steuerpflichtigen EU-Lieferungen"},
               %{accountnumber: "38360", accountname: "Umsatzsteuer nicht fällig aus im Inland steuerpflichtigen EU-Lieferungen 19 %"}
             ]},
                      %{
           accountgroupname: "Rechnungsabgrenzungsposten",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "39000", accountname: "Passive Rechnungsabgrenzung"},
               %{accountnumber: "39500", accountname: "Abgrenzung unterjährig pauschal gebuchter Abschreibungen für BWA"}
             ]}
       ]}, %{
       accountclass: "4", accountclassname: "Betriebliche Erträge",
       accountgroups: [
         %{
           accountgroupname: "Erträge aus Mitgliedsbeiträgen, Aufnahmegebühren und Umlagen (nur Vereine)",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "40000", accountname: "Echte Mitgliedsbeiträge"},
               %{accountnumber: "40100", accountname: "Aufnahmegebühren"},
               %{accountnumber: "40200", accountname: "Einnahmen aus Mitgliederumlagen"}
             ]},
         %{
           accountgroupname: "Erträge aus Erbschaften und Vermächtnissen (Vereine und Stiftungen) / Umsatzerlöse (gGmbH)",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "40300", accountname: "Einnahmen aus Schenkungen"},
               %{accountnumber: "40310", accountname: "Einnahmen aus Erbschaften"},
               %{accountnumber: "40320", accountname: "Einnahmen aus Vermächtnissen"},
               %{accountnumber: "40330", accountname: "Übrige ertragsteuerneutrale Einnahmen"}
             ]},
         %{
           accountgroupname: "Erträge aus Spenden",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "40400", accountname: "Erträge aus Spenden / Zuwendungen"},
               %{accountnumber: "40450", accountname: "Geldzuwendungen gegen Zuwendungsbestätigung"},
               %{accountnumber: "40500", accountname: "Geldzuwendungen ohne Zuwendungsbestätigung"},
               %{accountnumber: "40550", accountname: "Sachzuwendungen gegen Zuwendungsbestätigung"},
               %{accountnumber: "40600", accountname: "Sachzuwendungen ohne Zuwendungsbestätigung"},
               %{accountnumber: "40650", accountname: "Aufwandszuwendungen gegen Zuwendungsbestätigung"},
               %{accountnumber: "40700", accountname: "Aufwandszuwendungen ohne Zuwendungsbestätigung"},
               %{accountnumber: "40750", accountname: "Ertrag aus Spendenverbrauch"}
             ]},
         %{
           accountgroupname: "Umsatzerlöse",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "40900", accountname: "Umsatzerlöse"},
               %{accountnumber: "41000", accountname: "Sonstige steuerfreie Umsätze Inland"},
               %{accountnumber: "41010", accountname: "Erlöse aus Eintrittsgeldern steuerfrei"},
               %{accountnumber: "41030", accountname: "Erlöse aus Teilnehmer- und Nutzungsgebühren steuerfrei"},
               %{accountnumber: "41050", accountname: "Erlöse aus Veranstaltungen steuerfrei"},
               %{accountnumber: "41070", accountname: "Erlöse aus Fortbildung / Unterricht steuerfrei"},
               %{accountnumber: "41090", accountname: "Erlöse aus Reisen steuerfrei"},
               %{accountnumber: "41110", accountname: "Erlöse aus Werbung steuerfrei"},
               %{accountnumber: "41130", accountname: "Erlöse aus Zuwendungen Dritter (Sponsoren) steuerfrei"},
               %{accountnumber: "41200", accountname: "Steuerfreie Umsätze nach § 4 Nr. 1a UStG"},
               %{accountnumber: "41250", accountname: "Steuerfreie Innergemeinschaftliche Lieferungen nach § 4 Nr. 1b UStG"},
               %{accountnumber: "41270", accountname: "Steuerfreie Umsätze § 4 Nr. 8 ff. UStG"},
               %{accountnumber: "41280", accountname: "Steuerfreie Umsätze nach § 4 Nr. 12 UStG (Vermietung und Verpachtung)"},
               %{accountnumber: "41300", accountname: "Lieferungen des ersten Abnehmers bei innergemeinschaftlichen Dreiecksgeschäften § 25b Abs. 2 UStG"},
               %{accountnumber: "41350", accountname: "Steuerfreie innergemeinschaftliche Lieferungen von Neufahrzeugen an Abnehmer ohne Umsatzsteuer-Identifikationsnummer"},
               %{accountnumber: "41360", accountname: "Umsatzerlöse nach §§ 25 und 25a UStG 19 % USt"},
               %{accountnumber: "41380", accountname: "Umsatzerlöse nach §§ 25 und 25a UStG ohne USt"},
               %{accountnumber: "41390", accountname: "Umsatzerlöse aus Reiseleistungen § 25 Abs. 2 UStG, steuerfrei"},
               %{accountnumber: "41400", accountname: "Steuerfreie Umsätze Offshore etc."},
               %{accountnumber: "41500", accountname: "Sonstige steuerfreie Umsätze (z. B. § 4 Nr. 2 bis 7 UStG)"},
               %{accountnumber: "41600", accountname: "Steuerfreie Umsätze ohne Vorsteuerabzug zum Gesamtumsatz gehörend, § 4 UStG"},
               %{accountnumber: "41650", accountname: "Steuerfreie Umsätze ohne Vorsteuerabzug zum Gesamtumsatz gehörend"},
               %{accountnumber: "41800", accountname: "Erlöse, die mit den Durchschnittssätzen des § 24 UStG versteuert werden"},
               %{accountnumber: "41840", accountname: "Steuerfreie Erlöse Kleinunternehmernach § 19 Abs. 1 UStG"},
               %{accountnumber: "41850", accountname: "Erlöse als Kleinunternehmer nach § 19 Abs. 1 UStG a. F."},
               %{accountnumber: "42000", accountname: "Erlöse"},
               %{accountnumber: "42010", accountname: "Erlöse aus Eintrittsgeldern"},
               %{accountnumber: "42030", accountname: "Erlöse aus Teilnehmer-/Nutzungsgebühren"},
               %{accountnumber: "42050", accountname: "Erlöse aus Veranstaltungen"},
               %{accountnumber: "42070", accountname: "Erlöse aus Fortbildung/Unterricht"},
               %{accountnumber: "42090", accountname: "Erlöse aus Reisen"},
               %{accountnumber: "42110", accountname: "Erlöse aus Werbung"},
               %{accountnumber: "42130", accountname: "Erlöse aus Zuwendungen Dritter (Sponsoren)"},
               %{accountnumber: "42201", accountname: "Erlöse aus der Verwertung von Altpapier § 64 Abs. 5 AO"},
               %{accountnumber: "42202", accountname: "Erlöse aus der Verwertung von Altmaterial § 64 Abs. 5 AO"},
               %{accountnumber: "42203", accountname: "Erlöse aus Werbung § 64 Abs. 6 AO"},
               %{accountnumber: "42204", accountname: "Erlöse aus Totalisation § 64 Abs. 6 AO"},
               %{accountnumber: "42205", accountname: "Erlöse aus der zweiten Fraktionierungsstufe der Blutspendedienste § 64 Abs. 6 AO"},
               %{accountnumber: "42900", accountname: "Erlöse 0 % USt"},
               %{accountnumber: "43000", accountname: "Erlöse 7 % USt"},
               %{accountnumber: "43010", accountname: "Erlöse aus Eintrittsgeldern 7 % USt"},
               %{accountnumber: "43030", accountname: "Erlöse aus Teilnehmer- und Nutzungsgebühren 7 % USt"},
               %{accountnumber: "43050", accountname: "Erlöse aus Veranstaltungen 7 % USt"},
               %{accountnumber: "43070", accountname: "Erlöse aus Fortbildung/Unterricht 7 % USt"},
               %{accountnumber: "43090", accountname: "Erlöse aus Reisen 7 % USt"},
               %{accountnumber: "43110", accountname: "Erlöse aus Werbung 7 % USt (übertragene Weberechte)"},
               %{accountnumber: "43180", accountname: "Erlöse aus im Inland steuerpflichtigen EU-Lieferungen 7 % USt"},
               %{accountnumber: "43190", accountname: "Erlöse aus im Inland steuerpflichtigen EU-Lieferungen 19 % USt"},
               %{accountnumber: "43200", accountname: "Erlöse aus im anderen EU-Land steuerpflichtigen Lieferungen, im Inland nicht steuerbar"},
               %{accountnumber: "43310", accountname: "Erlöse aus im anderen EU-Land steuerpflichtigen elektronischen Dienstleistungen"},
               %{accountnumber: "43340", accountname: "Erlöse 7 % USt"},
               %{accountnumber: "43350", accountname: "Erlöse aus Lieferungen von Mobilfunkgeräten, Tablet-Computern, Spielekonsolen und integrierten Schaltkreisen, für die der Leistungsempfänger die Umsatzsteuer nach § 13b UStG schuldet"},
               %{accountnumber: "43360", accountname: "Erlöse aus im anderen EU-Land steuerpflichtigen sonstigen Leistungen, für die der Leistungsempfänger die Umsatzsteuer schuldet"},
               %{accountnumber: "43370", accountname: "Erlöse aus Leistungen, für die der Leistungsempfänger die Umsatzsteuer nach § 13b UStG schuldet"},
               %{accountnumber: "43380", accountname: "Erlöse aus im Drittland steuerbaren Leistungen, im Inland nicht steuerbare Umsätze"},
               %{accountnumber: "43390", accountname: "Erlöse aus im anderen EU-Land steuerbaren Leistungen, im Inland nicht steuerbare Umsätze"},
               %{accountnumber: "43400", accountname: "Erlöse 16 % USt"},
               %{accountnumber: "44000", accountname: "Erlöse 19 % USt"},
               %{accountnumber: "44010", accountname: "Erlöse aus Eintrittsgeldern 19 % USt"},
               %{accountnumber: "44030", accountname: "Erlöse aus Teilnehmer-/Nutzungsgebühren 19 % USt"},
               %{accountnumber: "44050", accountname: "Erlöse aus Veranstaltungen 19 % USt"},
               %{accountnumber: "44070", accountname: "Erlöse aus Fortbildung / Unterricht 19 % USt"},
               %{accountnumber: "44090", accountname: "Erlöse aus Reisen 19 % USt"},
               %{accountnumber: "44110", accountname: "Erlöse aus Werbung 19 % USt (in Eigenregie)"},
               %{accountnumber: "44130", accountname: "Erlöse aus Zuwendungen Dritter (Sponsoren) 19 % USt"},
               %{accountnumber: "44190", accountname: "Erlöse 19 % USt"},
               %{accountnumber: "44480", accountname: "Erlöse aus Geldspielautomaten 19 % USt"},
               %{accountnumber: "44490", accountname: "Erlöse aus im Inland steuerpflichtigen elektronischen Dienstleistungen 19 % USt"},
               %{accountnumber: "44990", accountname: "Nebenerlöse (Bezug zu Materialaufwand)"},
               %{accountnumber: "45100", accountname: "Erlöse Abfallverwertung"},
               %{accountnumber: "45200", accountname: "Erlöse Leergut"},
               %{accountnumber: "45600", accountname: "Provisionsumsätze"},
               %{accountnumber: "45640", accountname: "Provisionsumsätze, steuerfrei § 4 Nr. 8 ff. UStG"},
               %{accountnumber: "45650", accountname: "Provisionsumsätze, steuerfrei § 4 Nr. 5 UStG"},
               %{accountnumber: "45660", accountname: "Provisionsumsätze 7 % USt"},
               %{accountnumber: "45690", accountname: "Provisionsumsätze 19 % USt"},
               %{accountnumber: "45700", accountname: "Sonstige Erträge aus Provisionen, Lizenzen und Patenten"},
               %{accountnumber: "45740", accountname: "Sonstige Erträge aus Provisionen, Lizenzen und Patenten, steuerfrei § 4 Nr. 8 ff. UStG"},
               %{accountnumber: "45750", accountname: "Sonstige Erträge aus Provisionen, Lizenzen und Patenten, steuerfrei § 4 Nr. 5 UStG"},
               %{accountnumber: "45760", accountname: "Sonstige Erträge aus Provisionen, Lizenzen und Patenten 7 % USt"},
               %{accountnumber: "45790", accountname: "Sonstige Erträge aus Provisionen, Lizenzen und Patenten 19 % USt"},
               %{accountnumber: "46900", accountname: "Nicht steuerbare Umsätze (Innenumsätze)"},
               %{accountnumber: "46950", accountname: "Umsatzsteuervergütungen, z. B. nach § 24 UStG"},
               %{accountnumber: "46990", accountname: "Direkt mit dem Umsatz verbundene Steuern"},
               %{accountnumber: "47000", accountname: "Erlösschmälerungen"},
               %{accountnumber: "47010", accountname: "Erlösschmälerungen für steuerfreie Umsätze nach § 4 Nr. 8 ff. UStG"},
               %{accountnumber: "47020", accountname: "Erlösschmälerungen für steuerfreie Umsätze nach § 4 Nr. 2 bis 7 UStG"},
               %{accountnumber: "47030", accountname: "Erlösschmälerungen für sonstige steuerfreie Umsätze ohne Vorsteuerabzug"},
               %{accountnumber: "47040", accountname: "Erlösschmälerungen für sonstige steuerfreie Umsätze mit Vorsteuerabzug"},
               %{accountnumber: "47050", accountname: "Erlösschmälerungen aus steuerfreien Umsätzen § 4 Nr. 1a UStG"},
               %{accountnumber: "47060", accountname: "Erlösschmälerungen für steuerfreie innergemeinschaftliche Dreiecksgeschäfte nach § 25b Abs. 2 und 4 UStG"},
               %{accountnumber: "47100", accountname: "Erlösschmälerungen 7 % USt"},
               %{accountnumber: "47190", accountname: "Erlösschmälerungen 0 % USt"},
               %{accountnumber: "47200", accountname: "Erlösschmälerungen 19 % USt"},
               %{accountnumber: "47240", accountname: "Erlösschmälerungen aus steuerfreien innergemeinschaftlichen Lieferungen"},
               %{accountnumber: "47250", accountname: "Erlösschmälerungen aus im Inland steuerpflichtigen EU-Lieferungen 7 % USt"},
               %{accountnumber: "47260", accountname: "Erlösschmälerungen aus im Inland steuerpflichtigen EU-Lieferungen 19 % USt"},
               %{accountnumber: "47270", accountname: "Erlösschmälerungen aus im anderen EU-Land steuerpflichtigen Lieferungen"},
               %{accountnumber: "47300", accountname: "Gewährte Skonti"},
               %{accountnumber: "47310", accountname: "Gewährte Skonti 7 % USt"},
               %{accountnumber: "47360", accountname: "Gewährte Skonti 19 % USt"},
               %{accountnumber: "47340", accountname: "Gewährte Skonti 0 % USt"},
               %{accountnumber: "47380", accountname: "Gewährte Skonti a. Lieferungen v. Mobilfunkgeräten etc., für die der Leistungsempfänger die Umsatzst. nach § 13b Abs. 2 Nr. 10 UStG schuldet"},
               %{accountnumber: "47410", accountname: "Gewährte Skonti aus Leistungen, für die der Leistungsempfänger die Umsatzsteuer nach § 13b UStG schuldet"},
               %{accountnumber: "47420", accountname: "Gewährte Skonti aus Erlöse aus im anderen EU-Land steuerpflichtigen sonstigen Leistungen, für die der Leistungsempfänger die Umsatzsteuer schuldet"},
               %{accountnumber: "47430", accountname: "Gewährte Skonti aus steuerfreien innergemeinschaftlichen Lieferungen § 4 Nr. 1b UStG"},
               %{accountnumber: "47450", accountname: "Gewährte Skonti aus im Inland steuerpflichtigen EU-Lieferungen"},
               %{accountnumber: "47460", accountname: "Gewährte Skonti aus im Inland steuerpflichtigen EU-Lieferungen 7 % USt"},
               %{accountnumber: "47480", accountname: "Gewährte Skonti aus im Inland steuerpflichtigen EU-Lieferungen 19 % USt"},
               %{accountnumber: "47500", accountname: "Gewährte Boni 7 % USt"},
               %{accountnumber: "47600", accountname: "Gewährte Boni 19 % USt"},
               %{accountnumber: "47690", accountname: "Gewährte Boni"},
               %{accountnumber: "47700", accountname: "Gewährte Rabatte"},
               %{accountnumber: "47800", accountname: "Gewährte Rabatte 7 % USt"},
               %{accountnumber: "47900", accountname: "Gewährte Rabatte 19 % USt"},
               %{accountnumber: "48330", accountname: "Andere Nebenerlöse"},
               %{accountnumber: "48600", accountname: "Grundstückserträge"},
               %{accountnumber: "48610", accountname: "Erlöse aus Vermietung und Verpachtung, umsatzsteuerfrei § 4 Nr. 12 UStG"},
               %{accountnumber: "48620", accountname: "Erlöse aus Vermietung und Verpachtung 19 % USt"},
               %{accountnumber: "48630", accountname: "Erlöse aus Vermietung und Verpachtung 7 % USt"},
               %{accountnumber: "49920", accountname: "Erträge aus Verwaltungskostenumlagen"}
             ]},
         %{
           accountgroupname: "Sonstige betriebliche Erträge",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "46000", accountname: "Unentgeltliche Wertabgaben"},
               %{accountnumber: "46500", accountname: "Unentgeltliche Erbringung einer sonstigen Leistung 7 % USt"},
               %{accountnumber: "46560", accountname: "Unentgeltliche Erbringung einer sonstigen Leistung 7 % USt"},
               %{accountnumber: "46590", accountname: "Unentgeltliche Erbringung einer sonstigen Leistung ohne USt"},
               %{accountnumber: "46600", accountname: "Unentgeltliche Erbringung einer sonstigen Leistung 19 % USt"},
               %{accountnumber: "46700", accountname: "Unentgeltliche Zuwendung von Waren 7 % USt"},
               %{accountnumber: "46760", accountname: "Unentgeltliche Zuwendung von Waren 7 % USt"},
               %{accountnumber: "46790", accountname: "Unentgeltliche Zuwendung von Waren ohne USt"},
               %{accountnumber: "46800", accountname: "Unentgeltliche Zuwendung von Waren 19 % USt"},
               %{accountnumber: "46860", accountname: "Unentgeltliche Zuwendung von Gegenständen 19 % USt"},
               %{accountnumber: "46890", accountname: "Unentgeltliche Zuwendung von Gegenständen ohne USt"},
               %{accountnumber: "48280", accountname: "Zuschüsse von Verbänden und Behörden"},
               %{accountnumber: "48290", accountname: "Sonstige Zuschüsse"},
               %{accountnumber: "48300", accountname: "Sonstige betriebliche Erträge"},
               %{accountnumber: "48320", accountname: "Sonstige betriebliche Erträge von verbundenen Unternehmen"},
               %{accountnumber: "48340", accountname: "Sonstige Erträge betrieblich und regelmäßig 16 % USt"},
               %{accountnumber: "48350", accountname: "Sonstige Erträge betrieblich und regelmäßig"},
               %{accountnumber: "48360", accountname: "Sonstige Erträge betrieblich und regelmäßig 19 % USt"},
               %{accountnumber: "48370", accountname: "Sonstige Erträge betriebsfremd und regelmäßig"},
               %{accountnumber: "48380", accountname: "Erstattete Vorsteuer anderer Länder"},
               %{accountnumber: "48390", accountname: "Sonstige Erträge unregelmäßig"},
               %{accountnumber: "48400", accountname: "Erträge aus der Währungsumrechnung"},
               %{accountnumber: "48410", accountname: "Sonstige Erträge betrieblich und regelmäßig, steuerfrei § 4 Nr. 8 ff. UStG"},
               %{accountnumber: "48420", accountname: "Sonstige betriebliche Erträge, steuerfrei z. B. § 4 Nr. 2 bis 7 UStG"},
               %{accountnumber: "48430", accountname: "Erträge aus Bewertung Finanzmittelfonds"},
               %{accountnumber: "48440", accountname: "Erlöse aus Verkäufen Sachanlagevermögen steuerfrei § 4 Nr. 1a UStG (bei Buchgewinn)"},
               %{accountnumber: "48450", accountname: "Erlöse aus Verkäufen Sachanlagevermögen 19 % USt (bei Buchgewinn)"},
               %{accountnumber: "48470", accountname: "Erträge aus der Währungsumrechnung (nicht § 256a HGB)"},
               %{accountnumber: "48480", accountname: "Erlöse aus Verkäufen Sachanlagevermögen steuerfrei § 4 Nr. 1b UStG (bei Buchgewinn)"},
               %{accountnumber: "48490", accountname: "Erlöse aus Verkäufen Sachanlagevermögen (bei Buchgewinn)"},
               %{accountnumber: "48500", accountname: "Erlöse aus Verkäufen immaterieller Vermögensgegenstände (bei Buchgewinn)"},
               %{accountnumber: "48510", accountname: "Erlöse aus Verkäufen Finanzanlagen (bei Buchgewinn)"},
               %{accountnumber: "48520", accountname: "Erlöse aus Verkäufen Finanzanlagen § 3 Nr. 40 EStG bzw. § 8b Abs. 2 KStG (bei Buchgewinn)"},
               %{accountnumber: "48550", accountname: "Anlagenabgänge Sachanlagen (Restbuchwert bei Buchgewinn)"},
               %{accountnumber: "48560", accountname: "Anlagenabgänge immaterielle Vermögensgegenstände (Restbuchwert bei Buchgewinn)"},
               %{accountnumber: "48570", accountname: "Anlagenabgänge Finanzanlagen (Restbuchwert bei Buchgewinn)"},
               %{accountnumber: "48580", accountname: "Anlagenabgänge Finanzanlagen § 3 Nr. 40 EStG bzw. § 8b Abs. 2 KStG (Restbuchwert bei Buchgewinn)"},
               %{accountnumber: "49040", accountname: "Abgänge Wertpapiere des Umlaufvermögens § 8b Abs. 2 KStG (Buchwert bei Buchgewinn)"},
               %{accountnumber: "49050", accountname: "Erträge aus dem Abgang von Gegenständen des Umlaufvermögens (außer Vorräte)"},
               %{accountnumber: "49060", accountname: "Erträge aus dem Abgang von Gegenständen des Umlaufvermögens (außer Vorräte) § 3 Nr. 40 EStG bzw. § 8b Abs. 2 KStG"},
               %{accountnumber: "49100", accountname: "Erträge aus Zuschreibungen des Sachanlagevermögens"},
               %{accountnumber: "49110", accountname: "Erträge aus Zuschreibungen des immateriellen Anlagevermögens"},
               %{accountnumber: "49120", accountname: "Erträge aus Zuschreibungen des Finanzanlagevermögens"},
               %{accountnumber: "49130", accountname: "Erträge aus Zuschreibungen des Finanzanlagevermögens § 3 Nr. 40 EStG bzw. § 8b Abs. 3 S. 9 KStG"},
               %{accountnumber: "49140", accountname: "Erträge aus Zuschreibungen § 3 Nr. 40 EStG bzw. § 8b Abs. 2 KStG"},
               %{accountnumber: "49150", accountname: "Erträge aus Zuschreibungen des Umlaufvermögens (außer Vorräte)"},
               %{accountnumber: "49160", accountname: "Erträge aus Zuschreibungen des Umlaufvermögens § 3 Nr. 40 EStG bzw. § 8b Abs. 3 S. 9 KStG"},
               %{accountnumber: "49200", accountname: "Erträge aus der Herabsetzung der Pauschalwertberichtigung auf Forderungen"},
               %{accountnumber: "49230", accountname: "Erträge aus der Herabsetzung der Einzelwertberichtigung auf Forderungen"},
               %{accountnumber: "49250", accountname: "Erträge aus abgeschriebenen Forderungen"},
               %{accountnumber: "49270", accountname: "Erträge aus der Auflösung einer steuerlichen Rücklage nach § 6b Abs. 3 EStG"},
               %{accountnumber: "49290", accountname: "Erträge aus der Auflösung der Rücklage für Ersatzbeschaffung, R 6.6 EStR"},
               %{accountnumber: "49300", accountname: "Erträge aus der Auflösung von Rückstellungen"},
               %{accountnumber: "49320", accountname: "Erträge aus der Herabsetzung von Verbindlichkeiten"},
               %{accountnumber: "49350", accountname: "Erträge aus der Auflösung sonstiger steuerlicher Rücklagen"},
               %{accountnumber: "49370", accountname: "Erträge aus der Auflösung steuerrechtlicher Sonderabschreibungen"},
               %{accountnumber: "49380", accountname: "Erträge aus der Auflösung einer steuerlichen Rücklage nach § 4g EStG"},
               %{accountnumber: "49400", accountname: "Verrechnete sonstige Sachbezüge (keine Waren)"},
               %{accountnumber: "49410", accountname: "Sachbezüge 7 % USt (Waren)"},
               %{accountnumber: "49440", accountname: "Verrechnete sonstige Sachbezüge aus Fahrzeug-Gestellung zum ermäßigten Umsatzsteuersatz"},
               %{accountnumber: "49450", accountname: "Sachbezüge 19 % USt (Waren)"},
               %{accountnumber: "49460", accountname: "Verrechnete sonstige Sachbezüge"},
               %{accountnumber: "49470", accountname: "Verrechnete sonstige Sachbezüge aus Fahrzeug-Gestellung 19 % USt"},
               %{accountnumber: "49480", accountname: "Verrechnete sonstige Sachbezüge 19 % USt"},
               %{accountnumber: "49490", accountname: "Verrechnete sonstige Sachbezüge ohne Umsatzsteuer"},
               %{accountnumber: "49600", accountname: "Periodenfremde Erträge"},
               %{accountnumber: "49700", accountname: "Versicherungsentschädigungen und Schadenersatzleistungen"},
               %{accountnumber: "49720", accountname: "Erstattungen Aufwendungsausgleichsgesetz"},
               %{accountnumber: "49750", accountname: "Investitionszuschüsse (steuerpflichtig)"},
               %{accountnumber: "49800", accountname: "Investitionszulagen (steuerfrei)"},
               %{accountnumber: "49810", accountname: "Steuerfreie Erträge aus der Auflösung von steuerlichen Rücklagen"},
               %{accountnumber: "49820", accountname: "Sonstige steuerfreie Betriebseinnahmen"},
               %{accountnumber: "49860", accountname: "Ertrag aus pauschaler Vorsteuer § 23a UStG"},
               %{accountnumber: "49870", accountname: "Erträge aus der Aktivierung unentgeltlich erworbener Vermögensgegenstände"},
               %{accountnumber: "49890", accountname: "Kostenerstattungen, Rückvergütungen und Gutschriften für frühere Jahre"}
             ]},
         %{
           accountgroupname: "Erhöhung oder Verminderung des Bestandes an fertigen und unfertigen Erzeugnissen",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "48000", accountname: "Bestandsveränderungen - fertige Erzeugnisse"},
               %{accountnumber: "48100", accountname: "Bestandsveränderungen - unfertige Erzeugnisse"},
               %{accountnumber: "48150", accountname: "Bestandsveränderungen - unfertige Leistungen"}
             ]},
         %{
           accountgroupname: "Erhöhung oder Verminderung des Bestands in Ausführung befindlicher Bauaufträge",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "48160", accountname: "Bestandsveränderungen in Ausführung befindlicher Bauaufträge"}
             ]},
         %{
           accountgroupname: "Erhöhung oder Verminderung des Bestands in Arbeit befindlicher Aufträge",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "48180", accountname: "Bestandsveränderungen in Arbeitbefindlicher Aufträge"}
             ]},
         %{
           accountgroupname: "Andere aktivierte Eigenleistungen",
           accounttypecode: "ertrag",
             accounts: [
               %{accountnumber: "48200", accountname: "Andere aktivierte Eigenleistungen"},
               %{accountnumber: "48240", accountname: "Aktivierte Eigenleistungen (den Herstellungskosten zurechenbare Fremdkapitalzinsen)"},
               %{accountnumber: "48250", accountname: "Aktivierte Eigenleistungen zur Erstellung von selbst geschaffenen immateriellen Vermögensgegenständen"}
             ]}
       ]
     }, %{
       accountclass: "5", accountclassname: "Betriebliche Aufwendungen",
       accountgroups: [
         %{
           accountgroupname: "Aufwendungen für Roh-, Hilfs- und Betriebsstoffe und für bezogene Waren",
           accounttypecode: "aufwand",

             accounts: [
               %{accountnumber: "50000", accountname: "Aufwendungen für Roh-, Hilfs- und Betriebsstoffe und für bezogene Waren"},
               %{accountnumber: "51000", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe"},
               %{accountnumber: "51100", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe 7 % Vorsteuer"},
               %{accountnumber: "51290", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe ohne Vorsteuerabzug"},
               %{accountnumber: "51300", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe 19 % Vorsteuer"},
               %{accountnumber: "51600", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe, innergemeinschaftlicher Erwerb 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "51620", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe, innergemeinschaftlicher Erwerb 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "51660", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe, innergemeinschaftlicher Erwerb ohne Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "51670", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe, innergemeinschaftlicher Erwerb ohne Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "51700", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe 5,5 % Vorsteuer"},
               %{accountnumber: "51710", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe 9,0 % / 7,8 % Vorsteuer"},
               %{accountnumber: "51750", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe aus einem USt-Lager § 13a UStG 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "51760", accountname: "Einkauf Roh-, Hilfs- und Betriebsstoffe aus einem USt-Lager § 13a UStG 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "51890", accountname: "Erwerb Roh-, Hilfs- und Betriebsstoffe als letzter Abnehmer innerhalb Dreiecksgeschäft 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "51900", accountname: "Energiestoffe (Fertigung)"},
               %{accountnumber: "51910", accountname: "Energiestoffe (Fertigung) 7 % Vorsteuer"},
               %{accountnumber: "51920", accountname: "Energiestoffe (Fertigung) 19 % Vorsteuer"},
               %{accountnumber: "52000", accountname: "Wareneingang"},
               %{accountnumber: "53000", accountname: "Wareneingang 7 % Vorsteuer"},
               %{accountnumber: "53470", accountname: "Wareneingang 7 % Vorsteuer"},
               %{accountnumber: "53490", accountname: "Wareneingang ohne Vorsteuerabzug"},
               %{accountnumber: "54000", accountname: "Wareneingang 19 % Vorsteuer"},
               %{accountnumber: "54180", accountname: "Wareneingang 19 % Vorsteuer"},
               %{accountnumber: "54200", accountname: "Innergemeinschaftlicher Erwerb 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "54250", accountname: "Innergemeinschaftlicher Erwerb 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "54300", accountname: "Innergemeinschaftlicher Erwerb ohne Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "54350", accountname: "Innergemeinschaftlicher Erwerb ohne Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "54400", accountname: "Innergemeinschaftlicher Erwerb von Neufahrzeugen von Lieferanten ohne Umsatzsteuer-Identifikationsnummer 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "55050", accountname: "Wareneingang 5,5 % Vorsteuer"},
               %{accountnumber: "55400", accountname: "Wareneingang zum Durchschnittssatz nach § 24 UStG 9,0 % / 7,8 % Vorsteuer"},
               %{accountnumber: "55500", accountname: "Steuerfreier innergemeinschaftlicher Erwerb"},
               %{accountnumber: "55510", accountname: "Wareneingang im Drittland steuerbar"},
               %{accountnumber: "55520", accountname: "Erwerb 1. Abnehmer innerhalb eines Dreieckgeschäftes"},
               %{accountnumber: "55530", accountname: "Erwerb Waren als letzter Abnehmer innerhalb Dreiecksgeschäft 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "55580", accountname: "Wareneingang im anderen EU-Land steuerbar"},
               %{accountnumber: "55590", accountname: "Steuerfreie Einfuhren"},
               %{accountnumber: "55600", accountname: "Waren aus einem Umsatzsteuerlager, § 13a UStG 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "55650", accountname: "Waren aus einem Umsatzsteuerlager, § 13a UStG 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "56000", accountname: "Nicht abziehbare Vorsteuer"},
               %{accountnumber: "56100", accountname: "Nicht abziehbare Vorsteuer 7 %"},
               %{accountnumber: "56600", accountname: "Nicht abziehbare Vorsteuer 19 %"},
               %{accountnumber: "57000", accountname: "Nachlässe"},
               %{accountnumber: "57010", accountname: "Nachlässe aus Einkauf Roh-, Hilfs- und Betriebsstoffe"},
               %{accountnumber: "57100", accountname: "Nachlässe 7 % Vorsteuer"},
               %{accountnumber: "57140", accountname: "Nachlässe aus Einkauf Roh-, Hilfs- und Betriebsstoffe 7 % Vorsteuer"},
               %{accountnumber: "57150", accountname: "Nachlässe aus Einkauf Roh-, Hilfs- und Betriebsstoffe 19 % Vorsteuer"},
               %{accountnumber: "57170", accountname: "Nachlässe aus Einkauf Roh-, Hilfs- und Betriebsstoffe, innergemeinschaftlicher Erwerb 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "57180", accountname: "Nachlässe aus Einkauf Roh-, Hilfs- und Betriebsstoffe, innergemeinschaftlicher Erwerb 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "57200", accountname: "Nachlässe 19 % Vorsteuer"},
               %{accountnumber: "57240", accountname: "Nachlässe aus innergemeinschaftlichem Erwerb 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "57250", accountname: "Nachlässe aus innergemeinschaftlichem Erwerb 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "57300", accountname: "Erhaltene Skonti"},
               %{accountnumber: "57310", accountname: "Erhaltene Skonti 7 % Vorsteuer"},
               %{accountnumber: "57330", accountname: "Erhaltene Skonti aus Einkauf Roh-, Hilfs- und Betriebsstoffe"},
               %{accountnumber: "57340", accountname: "Erhaltene Skonti aus Einkauf Roh-, Hilfs- und Betriebsstoffe 7 % Vorsteuer"},
               %{accountnumber: "57360", accountname: "Erhaltene Skonti 19 % Vorsteuer"},
               %{accountnumber: "57380", accountname: "Erhaltene Skonti aus Einkauf Roh-, Hilfs- und Betriebsstoffe 19 % Vorsteuer"},
               %{accountnumber: "57410", accountname: "Erhaltene Skonti aus Einkauf Roh-, Hilfs- und Betriebsstoffe aus steuerpflichtigem innergemeinschaftlichem Erwerb 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "57430", accountname: "Erhaltene Skonti aus Einkauf Roh-, Hilfs- und Betriebsstoffe aus steuerpflichtigem innergemeinschaftlichem Erwerb 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "57440", accountname: "Erhaltene Skonti aus Einkauf Roh-, Hilfs- und Betriebsstoffe aus steuerpflichtigem innergemeinschaftlichem Erwerb"},
               %{accountnumber: "57450", accountname: "Erhaltene Skonti aus steuerpflichtigem innergemeinschaftlichem Erwerb"},
               %{accountnumber: "57460", accountname: "Erhaltene Skonti aus steuerpflichtigem innergemeinschaftlichem Erwerb 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "57480", accountname: "Erhaltene Skonti aus steuerpflichtigem innergemeinschaftlichem Erwerb 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "57500", accountname: "Erhaltene Boni 7 % Vorsteuer"},
               %{accountnumber: "57530", accountname: "Erhaltene Boni aus Einkauf Roh-, Hilfs- und Betriebsstoffe"},
               %{accountnumber: "57540", accountname: "Erhaltene Boni aus Einkauf Roh-, Hilfs- und Betriebsstoffe 7 % Vorsteuer"},
               %{accountnumber: "57550", accountname: "Erhaltene Boni aus Einkauf Roh-, Hilfs- und Betriebsstoffe 19 % Vorsteuer"},
               %{accountnumber: "57600", accountname: "Erhaltene Boni 19 % Vorsteuer"},
               %{accountnumber: "57690", accountname: "Erhaltene Boni"},
               %{accountnumber: "57700", accountname: "Erhaltene Rabatte"},
               %{accountnumber: "57800", accountname: "Erhaltene Rabatte 7 % Vorsteuer"},
               %{accountnumber: "57830", accountname: "Erhaltene Rabatte aus Einkauf Roh-, Hilfs- und Betriebsstoffe"},
               %{accountnumber: "57840", accountname: "Erhaltene Rabatte aus Einkauf Roh-, Hilfs- und Betriebsstoffe 7 % Vorsteuer"},
               %{accountnumber: "57850", accountname: "Erhaltene Rabatte aus Einkauf Roh-, Hilfs- und Betriebsstoffe 19 % Vorsteuer"},
               %{accountnumber: "57870", accountname: "Erhaltene Skonti aus Einkauf Roh-, Hilfs- und Betriebsstoffe 9,0 % Vorsteuer"},
               %{accountnumber: "57900", accountname: "Erhaltene Rabatte 19 % Vorsteuer"},
               %{accountnumber: "57920", accountname: "Erhaltene Skonti aus Erwerb Roh-, Hilfs- und Betriebsstoffe als letzter Abnehmer innerhalb Dreiecksgeschäft 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "57930", accountname: "Erhaltene Skonti aus Erwerb Waren als letzter Abnehmer innerhalb Dreiecksgeschäft 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "57940", accountname: "Erhaltene Skonti 5,5 % Vorsteuer"},
               %{accountnumber: "57950", accountname: "Erhaltene Skonti 9,0 % Vorsteuer"},
               %{accountnumber: "57980", accountname: "Erhaltene Skonti aus Einkauf Roh-, Hilfs- und Betriebsstoffe 5,5 % Vorsteuer"},
               %{accountnumber: "58000", accountname: "Bezugsnebenkosten"},
               %{accountnumber: "58200", accountname: "Leergut"},
               %{accountnumber: "58400", accountname: "Zölle und Einfuhrabgaben"},
               %{accountnumber: "58600", accountname: "Verrechnete Stoffkosten (Gegenkonto zu 5000 0 – 5099)"},
               %{accountnumber: "58800", accountname: "Bestandsveränderungen Roh-, Hilfs- und Betriebsstoffe sowie bezogene Waren"},
               %{accountnumber: "58810", accountname: "Bestandsveränderungen Waren"},
               %{accountnumber: "58850", accountname: "Bestandsveränderungen Roh-, Hilfs- und Betriebsstoffe"}
             ]},
         %{
           accountgroupname: "Aufwendungen für bezogene Leistungen",
           accounttypecode: "aufwand",

             accounts: [
               %{accountnumber: "59000", accountname: "Fremdleistungen"},
               %{accountnumber: "59060", accountname: "Fremdleistungen 19 % Vorsteuer"},
               %{accountnumber: "59080", accountname: "Fremdleistungen 7 % Vorsteuer"},
               %{accountnumber: "59090", accountname: "Fremdleistungen ohne Vorsteuer"},
               %{accountnumber: "59100", accountname: "Bauleistungen eines im Inland ansässigen Unternehmers 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "59130", accountname: "Sonstige Leistungen eines im anderen EU-Land ansässigen Unternehmers 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "59150", accountname: "Leistungen eines im Ausland ansässigen Unternehmers 7 % Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "59200", accountname: "Bauleistungen eines im Inland ansässigen Unternehmers 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "59230", accountname: "Sonstige Leistungen eines im anderen EU-Land ansässigen Unternehmers 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "59250", accountname: "Leistungen eines im Ausland ansässigen Unternehmers 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "59300", accountname: "Bauleistungen eines im Inland ansässigen Unternehmers ohne Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "59330", accountname: "Sonstige Leistungen eines im anderen EU-Land ansässigen Unternehmers ohne Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "59350", accountname: "Leistungen eines im Ausland ansässigen Unternehmers ohne Vorsteuer und 7 % Umsatzsteuer"},
               %{accountnumber: "59400", accountname: "Bauleistungen eines im Inland ansässigen Unternehmers ohne Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "59430", accountname: "Sonstige Leistungen eines im anderen EU-Land ansässigen Unternehmers ohne Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "59450", accountname: "Leistungen eines im Ausland ansässigen Unternehmers ohne Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "59500", accountname: "Erhaltene Skonti aus Leistungen, für die als Leistungsempfänger die Steuer nach § 13b UStG geschuldet wird"},
               %{accountnumber: "59510", accountname: "Erhaltene Skonti aus Leistungen, für die als Leistungsempfänger die Steuer nach § 13b UStG geschuldet wird 19 % Vorsteuer und 19 % Umsatzsteuer"},
               %{accountnumber: "59530", accountname: "Erhaltene Skonti aus Leistungen, für die als Leistungsempfänger die Steuer nach § 13b UStG geschuldet wird ohne Vorsteuer aber mit Umsatzsteuer"},
               %{accountnumber: "59540", accountname: "Erhaltene Skonti aus Leistungen, für die als Leistungsempfänger die Steuer nach § 13b UStG geschuldet wird ohne Vorsteuer, mit 19 % Umsatzsteuer"},
               %{accountnumber: "59600", accountname: "Leistungen nach § 13b UStG mit Vorsteuerabzug"},
               %{accountnumber: "59650", accountname: "Leistungen nach § 13b UStG ohne Vorsteuerabzug"},
               %{accountnumber: "59700", accountname: "Fremdleistungen (Miet- und Pachtzinsen bewegliche Wirtschaftsgüter)"},
               %{accountnumber: "59750", accountname: "Fremdleistungen (Miet- und Pachtzinsen unbewegliche Wirtschaftsgüter)"},
               %{accountnumber: "59800", accountname: "Fremdleistungen (Entgelte für Rechte und Lizenzen)"}
             ]}
       ]
     }, %{
       accountclass: "6", accountclassname: "Betriebliche Aufwendungen",
       accountgroups: [
         %{
           accountgroupname: "Löhne und Gehälter",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "60000", accountname: "Löhne und Gehälter"},
               %{accountnumber: "60020", accountname: "Ehrenamtspauschale"},
               %{accountnumber: "60040", accountname: "Übungsleiterpauschale"},
               %{accountnumber: "60100", accountname: "Löhne"},
               %{accountnumber: "60200", accountname: "Gehälter"},
               %{accountnumber: "60240", accountname: "Geschäftsführergehälter der GmbH-Gesellschafter"},
               %{accountnumber: "60260", accountname: "Tantiemen Gesellschafter-Geschäftsführer"},
               %{accountnumber: "60270", accountname: "Geschäftsführergehälter"},
               %{accountnumber: "60290", accountname: "Tantiemen Arbeitnehmer"},
               %{accountnumber: "60300", accountname: "Aushilfslöhne"},
               %{accountnumber: "60350", accountname: "Löhne für Minijobs"},
               %{accountnumber: "60360", accountname: "Pauschale Steuer für Minijobber"},
               %{accountnumber: "60370", accountname: "Pauschale Steuer für Gesellschafter-Geschäftsführer"},
               %{accountnumber: "60390", accountname: "Pauschale Steuer für Arbeitnehmer"},
               %{accountnumber: "60400", accountname: "Pauschale Steuer für Aushilfen"},
               %{accountnumber: "60450", accountname: "Bedienungsgelder"},
               %{accountnumber: "60600", accountname: "Freiwillige soziale Aufwendungen, lohnsteuerpflichtig"},
               %{accountnumber: "60660", accountname: "Freiwillige Zuwendungen an Minijobber"},
               %{accountnumber: "60670", accountname: "Freiwillige Zuwendungen an Gesellschafter-Geschäftsführer"},
               %{accountnumber: "60690", accountname: "Pauschale Steuer auf sonstige Bezüge (z. B. Fahrtkostenzuschüsse)"},
               %{accountnumber: "60700", accountname: "Krankengeldzuschüsse"},
               %{accountnumber: "60710", accountname: "Sachzuwendungen und Dienstleistungen an Minijobber"},
               %{accountnumber: "60720", accountname: "Sachzuwendungen und Dienstleistungen an Arbeitnehmer"},
               %{accountnumber: "60730", accountname: "Sachzuwendungen und Dienstleistungen an Gesellschafter-Geschäftsführer"},
               %{accountnumber: "60750", accountname: "Zuschüsse der Agenturen für Arbeit (Haben)"},
               %{accountnumber: "60760", accountname: "Aufwendungen aus der Veränderung von Urlaubsrückstellungen"},
               %{accountnumber: "60770", accountname: "Aufwendungen aus der Veränderung von Urlaubsrückstellungen für Gesellschafter-Geschäftsführer"},
               %{accountnumber: "60790", accountname: "Aufwendungen aus der Veränderung von Urlaubsrückstellungen für Minijobber"},
               %{accountnumber: "60800", accountname: "Vermögenswirksame Leistungen"},
               %{accountnumber: "60900", accountname: "Fahrtkostenerstattung Wohnung / Arbeitsstätte"}
             ]},
         %{
           accountgroupname: "Soziale Abgaben und Aufwendungen für Altersversorgung und für Unterstützung",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "61000", accountname: "Soziale Abgaben und Aufwendungen für Altersversorgung und für Unterstützung"},
               %{accountnumber: "61100", accountname: "Gesetzliche soziale Aufwendungen"},
               %{accountnumber: "61200", accountname: "Beiträge zur Berufsgenossenschaft"},
               %{accountnumber: "61300", accountname: "Freiwillige soziale Aufwendungen, lohnsteuerfrei"},
               %{accountnumber: "61400", accountname: "Aufwendungen für Altersversorgung"},
               %{accountnumber: "61470", accountname: "Pauschale Steuer auf sonstige Bezüge (z. B. Direktversicherungen)"},
               %{accountnumber: "61490", accountname: "Aufwendungen für Altersversorgung für Gesellschafter-Geschäftsführer"},
               %{accountnumber: "61500", accountname: "Versorgungskassen"},
               %{accountnumber: "61600", accountname: "Aufwendungen für Unterstützung"},
               %{accountnumber: "61700", accountname: "Sonstige soziale Abgaben"},
               %{accountnumber: "61710", accountname: "Soziale Abgaben für Minijobber"}
             ]},
         %{
           accountgroupname: "Abschreibungen auf immaterielle Vermögensgegenstände des Anlagevermögens und Sachanlagen",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "62000", accountname: "Abschreibungen auf immaterielle Vermögensgegenstände"},
               %{accountnumber: "62010", accountname: "Abschreibungen auf selbst geschaffene immaterielle Vermögensgegenstände"},
               %{accountnumber: "62050", accountname: "Abschreibungen auf den Geschäfts- oder Firmenwert"},
               %{accountnumber: "62090", accountname: "Außerplanmäßige Abschreibungen auf den Geschäfts- oder Firmenwert"},
               %{accountnumber: "62100", accountname: "Außerplanmäßige Abschreibungen auf immaterielle Vermögensgegenstände"},
               %{accountnumber: "62110", accountname: "Außerplanmäßige Abschreibungen auf selbst geschaffene immaterielle Vermögensgegenstände"},
               %{accountnumber: "62200", accountname: "Abschreibungen auf Sachanlagen (ohne AfA auf Fahrzeuge und Gebäude)"},
               %{accountnumber: "62210", accountname: "Abschreibungen auf Gebäude"},
               %{accountnumber: "62220", accountname: "Abschreibungen auf Fahrzeuge"},
               %{accountnumber: "62300", accountname: "Außerplanmäßige Abschreibungen auf Sachanlagen"},
               %{accountnumber: "62310", accountname: "Absetzung für außergewöhnliche technische und wirtschaftliche Abnutzung der Gebäude"},
               %{accountnumber: "62320", accountname: "Absetzung für außergewöhnliche technische und wirtschaftliche Abnutzung der Fahrzeuge"},
               %{accountnumber: "62330", accountname: "Absetzung für außergewöhnliche technische und wirtschaftliche Abnutzung sonstiger Wirtschaftsgüter"},
               %{accountnumber: "62400", accountname: "Abschreibungen auf Sachanlagen auf Grund steuerlicher Sondervorschriften"},
               %{accountnumber: "62410", accountname: "Sonderabschreibungen nach § 7g Abs. 5 EStG (ohne Fahrzeuge)"},
               %{accountnumber: "62420", accountname: "Sonderabschreibungen nach § 7g Abs. 5 EStG (für Fahrzeuge)"},
               %{accountnumber: "62430", accountname: "Kürzung der Anschaffungs- oder Herstellungskosten nach § 7g Abs. 2 EStG (ohne Fahrzeuge)"},
               %{accountnumber: "62440", accountname: "Kürzung der Anschaffungs- oder Herstellungskosten nach § 7g Abs. 2 EStG (für Fahrzeuge)"},
               %{accountnumber: "62450", accountname: "Sonderabschreibungen nach § 7b EStG (Mietwohnungsneubau)"},
               %{accountnumber: "62490", accountname: "Abzugsbetrag nach § 6b EStG"},
               %{accountnumber: "62500", accountname: "Kaufleasing"},
               %{accountnumber: "62600", accountname: "Sofortabschreibung geringwertiger Wirtschaftsgüter"},
               %{accountnumber: "62620", accountname: "Abschreibungen auf aktivierte, geringwertige Wirtschaftsgüter"},
               %{accountnumber: "62640", accountname: "Abschreibungen auf den Sammelposten Wirtschaftsgüter"},
               %{accountnumber: "62660", accountname: "Außerplanmäßige Abschreibungen auf aktivierte geringwertige Wirtschaftsgüter"}
             ]},
         %{
           accountgroupname: "Abschreibung auf Vermögensgegenstände des Umlaufvermögens, soweit diese die üblichen Abschreibungen überschreiten",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "62700", accountname: "Abschreibungen auf sonstige Vermögensgegenstände des Umlaufvermögens (soweit unüblich hoch)"},
               %{accountnumber: "62720", accountname: "Abschreibungen auf Umlaufvermögen, steuerrechtlich bedingt (soweit unüblich hoch)"},
               %{accountnumber: "62780", accountname: "Abschreibungen auf Roh-, Hilfs- und Betriebsstoffe/Waren (soweit unüblich hoch)"},
               %{accountnumber: "62790", accountname: "Abschreibungen auf fertige und unfertige Erzeugnisse (soweit unüblich hoch)"},
               %{accountnumber: "62800", accountname: "Forderungsverluste (soweit unüblich hoch)"},
               %{accountnumber: "62810", accountname: "Forderungsverluste 7 % USt (soweit unüblich hoch)"},
               %{accountnumber: "62860", accountname: "Forderungsverluste 19 % USt (soweit unüblich hoch)"},
               %{accountnumber: "62900", accountname: "Abschreibungen auf Forderungen gegenüber Kapitalgesellschaften, an denen eine Beteiligung besteht (soweit unüblich hoch), § 3c EStG bzw. § 8b Abs. 3 KStG"},
               %{accountnumber: "62910", accountname: "Abschreibungen auf Forderungen gegenüber Gesellschaftern und nahe stehenden Personen (soweit unüblich hoch), § 3 Nr. 40 EStG bzw. § 8b Abs. 3 KStG8)"}             ]},
         %{
           accountgroupname: "Sonstige betriebliche Aufwendungen",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "63000", accountname: "Sonstige betriebliche Aufwendungen"},
               %{accountnumber: "63010", accountname: "Verwaltungskosten"},
               %{accountnumber: "63001", accountname: "Tatsächliche Kosten im Zusammenhang mit den Einnahmen nach § 64 Abs. 5 AO"},
               %{accountnumber: "63002", accountname: "Tatsächliche Kosten im Zusammenhang mit den Einnahmen nach § 64 Abs. 6 AO"},
               %{accountnumber: "63020", accountname: "Aufwandsentschädigungen / Erstattungen"},
               %{accountnumber: "63030", accountname: "Transportkosten"},
               %{accountnumber: "63040", accountname: "Veranstaltungskosten"},
               %{accountnumber: "63050", accountname: "Kosten der Mitgliederverwaltung"},
               %{accountnumber: "63060", accountname: "Interimskonto für Aufwendungen in einem anderen Land, bei denen eine Vorsteuervergütung möglich ist"},
               %{accountnumber: "63070", accountname: "Fremdleistungen/Fremdarbeiten"},
               %{accountnumber: "63080", accountname: "Sonstige Aufwendungen betrieblich und regelmäßig"},
               %{accountnumber: "63090", accountname: "Raumkosten"},
               %{accountnumber: "63100", accountname: "Miete (unbewegliche Wirtschaftsgüter)"},
               %{accountnumber: "63130", accountname: "Vergütungen an Gesellschafter für die miet- oder pachtweise Überlassung ihrer unbeweglichen Wirtschaftsgüter"},
               %{accountnumber: "63150", accountname: "Pacht (unbewegliche Wirtschaftsgüter)"},
               %{accountnumber: "63160", accountname: "Leasing (unbewegliche Wirtschaftsgüter)"},
               %{accountnumber: "63170", accountname: "Aufwendungen für gemietete oder gepachtete unbewegliche Wirtschaftsgüter, die gewerbesteuerlich hinzuzurechnen sind"},
               %{accountnumber: "63180", accountname: "Miet- und Pachtnebenkosten, die gewerbesteuerlich nicht hinzuzurechnen sind"},
               %{accountnumber: "63200", accountname: "Heizung"},
               %{accountnumber: "63250", accountname: "Gas, Strom, Wasser"},
               %{accountnumber: "63300", accountname: "Reinigung"},
               %{accountnumber: "63350", accountname: "Instandhaltung betrieblicher Räume"},
               %{accountnumber: "63400", accountname: "Abgaben für betrieblich genutzten Grundbesitz"},
               %{accountnumber: "63450", accountname: "Sonstige Raumkosten"},
               %{accountnumber: "63500", accountname: "Grundstücksaufwendungen betrieblich"},
               %{accountnumber: "63520", accountname: "Sonstige Grundstücksaufwendungen (neutral)"},
               %{accountnumber: "63900", accountname: "Zuwendungen, Spenden, steuerlich nicht abziehbar"},
               %{accountnumber: "63910", accountname: "Zuwendungen, Spenden für wissenschaftliche und kulturelle Zwecke"},
               %{accountnumber: "63920", accountname: "Zuwendungen, Spenden für mildtätige Zwecke"},
               %{accountnumber: "63930", accountname: "Zuwendungen, Spenden für kirchliche, religiöse und gemeinnützige Zwecke"},
               %{accountnumber: "63940", accountname: "Zuwendungen, Spenden an politische Parteien"},
               %{accountnumber: "63950", accountname: "Zuwendungen, Spenden in das zu erhaltende Vermögen (Vermögensstock) einer Stiftung für gemeinnützige Zwecke"},
               %{accountnumber: "63970", accountname: "Zuwendungen, Spenden in das zu erhaltende Vermögen (Vermögensstock) einer Stiftung für kirchliche, religiöse und gemeinnützige Zwecke"},
               %{accountnumber: "63980", accountname: "Zuwendungen, Spenden an Stiftungen in das zu erhaltende Vermögen (Vermögensstock) für wissenschaftliche, mildtätige, kulturelle Zwecke"},
               %{accountnumber: "64000", accountname: "Versicherungen"},
               %{accountnumber: "64050", accountname: "Versicherungen für Gebäude"},
               %{accountnumber: "64100", accountname: "Netto-Prämie für Rückdeckung künftiger Versorgungsleistungen"},
               %{accountnumber: "64200", accountname: "Beiträge"},
               %{accountnumber: "64300", accountname: "Sonstige Abgaben"},
               %{accountnumber: "64360", accountname: "Steuerlich abzugsfähige Verspätungszuschläge und Zwangsgelder"},
               %{accountnumber: "64370", accountname: "Steuerlich nicht abzugsfähige Verspätungszuschläge und Zwangsgelder"},
               %{accountnumber: "64400", accountname: "Ausgleichsabgabe nach dem Schwerbehindertengesetz"},
               %{accountnumber: "64500", accountname: "Reparaturen und Instandhaltung von Bauten"},
               %{accountnumber: "64600", accountname: "Reparaturen und Instandhaltung von technischen Anlagen und Maschinen"},
               %{accountnumber: "64700", accountname: "Reparaturen und Instandhaltungen von anderen Anlagen und Betriebs- und Geschäftsausstattung"},
               %{accountnumber: "64750", accountname: "Zuführung zu Aufwandsrückstellungen"},
               %{accountnumber: "64850", accountname: "Reparaturen und Instandhaltung von anderen Anlagen"},
               %{accountnumber: "64900", accountname: "Sonstige Reparaturen und Instandhaltungen"},
               %{accountnumber: "64950", accountname: "Wartungskosten für Hard- und Software"},
               %{accountnumber: "64980", accountname: "Mietleasing bewegliche Wirtschaftsgüter für technische Anlagen und Maschinen"},
               %{accountnumber: "65000", accountname: "Fahrzeugkosten"},
               %{accountnumber: "65200", accountname: "Fahrzeug-Versicherungen"},
               %{accountnumber: "65300", accountname: "Laufende Fahrzeug-Betriebskosten"},
               %{accountnumber: "65400", accountname: "Fahrzeug-Reparaturen"},
               %{accountnumber: "65500", accountname: "Garagenmiete"},
               %{accountnumber: "65600", accountname: "Mietleasing Kfz"},
               %{accountnumber: "65650", accountname: "Mietleasingaufwendungen für Elektrofahrzeuge und Fahrräder, die gewerbesteuerlich hinzuzurechnen sind"},
               %{accountnumber: "65700", accountname: "Sonstige Fahrzeugkosten"},
               %{accountnumber: "65800", accountname: "Mautgebühren"},
               %{accountnumber: "65950", accountname: "Fremdfahrzeugkosten"},
               %{accountnumber: "66000", accountname: "Werbekosten"},
               %{accountnumber: "66050", accountname: "Streuartikel"},
               %{accountnumber: "66100", accountname: "Geschenke abzugsfähig ohne § 37b EStG"},
               %{accountnumber: "66110", accountname: "Geschenke abzugsfähig mit § 37b EStG"},
               %{accountnumber: "66120", accountname: "Pauschale Steuer für Geschenke und Zuwendungen abzugsfähig"},
               %{accountnumber: "66200", accountname: "Geschenke nicht abzugsfähig ohne § 37b EStG"},
               %{accountnumber: "66210", accountname: "Geschenke nicht abzugsfähig mit § 37b EStG"},
               %{accountnumber: "66220", accountname: "Pauschale Steuer für Geschenke und Zuwendungen nicht abzugsfähig"},
               %{accountnumber: "66250", accountname: "Geschenke ausschließlich betrieblich genutzt"},
               %{accountnumber: "66290", accountname: "Zugaben mit § 37b EStG"},
               %{accountnumber: "66300", accountname: "Repräsentationskosten"},
               %{accountnumber: "66310", accountname: "Kosten der Öffentlichkeitsarbeit"},
               %{accountnumber: "66400", accountname: "Bewirtungskosten"},
               %{accountnumber: "66410", accountname: "Sonstige eingeschränkt abziehbare Betriebsausgaben (abziehbarer Anteil)"},
               %{accountnumber: "66420", accountname: "Sonstige eingeschränkt abziehbare Betriebsausgaben (nicht abziehbarer Anteil)"},
               %{accountnumber: "66430", accountname: "Aufmerksamkeiten"},
               %{accountnumber: "66440", accountname: "Nicht abzugsfähige Bewirtungskosten"},
               %{accountnumber: "66450", accountname: "Nicht abzugsfähige Betriebsausgaben aus Werbe- und Repräsentationskosten"},
               %{accountnumber: "66490", accountname: "Nicht abzugsfähige Ausgaben"},
               %{accountnumber: "66500", accountname: "Reisekosten"},
               %{accountnumber: "66600", accountname: "Reisekosten Übernachtungsaufwand"},
               %{accountnumber: "66630", accountname: "Reisekosten Fahrtkosten"},
               %{accountnumber: "66640", accountname: "Reisekosten Verpflegungsmehraufwand"},
               %{accountnumber: "66680", accountname: "Kilometergelderstattung"},
               %{accountnumber: "67000", accountname: "Kosten der Warenabgabe"},
               %{accountnumber: "67100", accountname: "Verpackungsmaterial"},
               %{accountnumber: "67400", accountname: "Ausgangsfrachten"},
               %{accountnumber: "67600", accountname: "Transportversicherungen"},
               %{accountnumber: "67700", accountname: "Verkaufsprovisionen"},
               %{accountnumber: "67800", accountname: "Fremdarbeiten (Vertrieb)"},
               %{accountnumber: "67900", accountname: "Aufwand für Gewährleistungen"},
               %{accountnumber: "68000", accountname: "Porto"},
               %{accountnumber: "68050", accountname: "Telefon"},
               %{accountnumber: "68100", accountname: "Internetkosten"},
               %{accountnumber: "68150", accountname: "Bürobedarf"},
               %{accountnumber: "68200", accountname: "Zeitschriften, Bücher, digitale Medien (Fachliteratur)"},
               %{accountnumber: "68210", accountname: "Fortbildungskosten"},
               %{accountnumber: "68220", accountname: "Freiwillige Sozialleistungen"},
               %{accountnumber: "68250", accountname: "Rechts- und Beratungskosten"},
               %{accountnumber: "68270", accountname: "Abschluss- und Prüfungskosten"},
               %{accountnumber: "68300", accountname: "Buchführungskosten"},
               %{accountnumber: "68330", accountname: "Vergütungen an Gesellschafter für die miet- oder pachtweise Überlassung ihrer beweglichen Wirtschaftsgüter"},
               %{accountnumber: "68350", accountname: "Mieten für Einrichtungen (bewegliche Wirtschaftsgüter)"},
               %{accountnumber: "68360", accountname: "Pacht (bewegliche Wirtschaftsgüter)"},
               %{accountnumber: "68370", accountname: "Aufwendungen für die zeitlich befristete Überlassung von Rechten (Lizenzen, Konzessionen)"},
               %{accountnumber: "68380", accountname: "Aufwendungen für gemietete oder gepachtete bewegliche Wirtschaftsgüter, die gewerbesteuerlich hinzuzurechnen sind"},
               %{accountnumber: "68400", accountname: "Mietleasing bewegliche Wirtschaftsgüter für Betriebs- und Geschäftsausstattung"},
               %{accountnumber: "68450", accountname: "Werkzeuge und Kleingeräte"},
               %{accountnumber: "68500", accountname: "Sonstiger Betriebsbedarf"},
               %{accountnumber: "68550", accountname: "Nebenkosten des Geldverkehrs"},
               %{accountnumber: "68560", accountname: "Aufwendungen aus Anteilen an Kapitalgesellschaften §§ 3 Nr. 40 und 3c EStG bzw. § 8b Abs. 1 und 4 KStG,"},
               %{accountnumber: "68570", accountname: "Veräußerungskosten § 3 Nr. 40 EStG bzw. § 8b Abs. 2 KStG (bei Buchgewinn)"},
               %{accountnumber: "68580", accountname: "Veräußerungskosten § 3 Nr. 40 EStG bzw. § 8b Abs. 2 i. V. m. § 8b Abs. 3 S. 3 KStG (bei Buchverlust)"},
               %{accountnumber: "68590", accountname: "Aufwendungen für Abraum- und Abfallbeseitigung"},
               %{accountnumber: "68600", accountname: "Nicht abziehbare Vorsteuer"},
               %{accountnumber: "68650", accountname: "Nicht abziehbare Vorsteuer 7 %"},
               %{accountnumber: "68710", accountname: "Nicht abziehbare Vorsteuer 19 %"},
               %{accountnumber: "68750", accountname: "Nicht abziehbare Hälfte der Aufsichtsratsvergütungen"},
               %{accountnumber: "68760", accountname: "Abziehbare Aufsichtsratsvergütungen"},
               %{accountnumber: "68790", accountname: "Verwahrentgelt"},
               %{accountnumber: "68800", accountname: "Aufwendungen aus der Währungsumrechnung"},
               %{accountnumber: "68810", accountname: "Aufwendungen aus der Währungsumrechnung (nicht § 256a HGB)"},
               %{accountnumber: "68830", accountname: "Aufwendungen aus Bewertung Finanzmittelfonds"},
               %{accountnumber: "68840", accountname: "Erlöse aus Verkäufen Sachanlagevermögen steuerfrei § 4 Nr. 1a UStG (bei Buchverlust)"},
               %{accountnumber: "68850", accountname: "Erlöse aus Verkäufen Sachanlagevermögen 19 % USt (bei Buchverlust)"},
               %{accountnumber: "68880", accountname: "Erlöse aus Verkäufen Sachanlagevermögen steuerfrei § 4 Nr. 1b UStG (bei Buchverlust)"},
               %{accountnumber: "68890", accountname: "Erlöse aus Verkäufen Sachanlagevermögen (bei Buchverlust)"},
               %{accountnumber: "68900", accountname: "Erlöse aus Verkäufen immaterieller Vermögensgegenstände (bei Buchverlust)"},
               %{accountnumber: "68910", accountname: "Erlöse aus Verkäufen Finanzanlagen (bei Buchverlust)"},
               %{accountnumber: "68920", accountname: "Erlöse aus Verkäufen Finanzanlagen § 3 Nr. 40 EStG bzw. § 8b Abs. 2 KStG i. V. m. § 8b Abs. 3 S. 3 KStG (bei Buchverlust)"},
               %{accountnumber: "68950", accountname: "Anlagenabgänge Sachanlagen (Restbuchwert bei Buchverlust)"},
               %{accountnumber: "68960", accountname: "Anlagenabgänge immaterielle Vermögensgegenstände (Restbuchwert bei Buchverlust)"},
               %{accountnumber: "68970", accountname: "Anlagenabgänge Finanzanlagen (Restbuchwert bei Buchverlust)"},
               %{accountnumber: "68980", accountname: "Anlagenabgänge Finanzanlagen § 3 Nr. 40 EStG bzw. § 8b Abs. 2 KStG i. V. m. § 8b Abs. 3 S. 3 KStG (Restbuchwert bei Buchverlust)"},
               %{accountnumber: "69040", accountname: "Abgänge Wertpapiere des Umlaufvermögens § 8b Abs. 2 KStG i. V. m. § 8b Abs. 3 S. 3 KStG (Buchwert bei Buchverlust)"},
               %{accountnumber: "69050", accountname: "Verluste aus dem Abgang von Gegenständen des Umlaufvermögens (außer Vorräte)"},
               %{accountnumber: "69060", accountname: "Verluste aus dem Abgang von Gegenständen des Umlaufvermögens außer Vorräte) § 3 Nr. 40 EStG bzw. § 8b Abs. 2 KStG i. V. m. § 8b Abs. 3 S. 3 KStG"},
               %{accountnumber: "69100", accountname: "Abschreibungen auf Umlaufvermögen außer Vorräte und Wertpapiere des Umlaufvermögens (übliche Höhe)"},
               %{accountnumber: "69120", accountname: "Abschreibungen auf Umlaufvermögen außer Vorräte und Wertpapiere des Umlaufvermögens, steuerrechtlich bedingt (übliche Höhe)"},
               %{accountnumber: "69180", accountname: "Aufwendungen aus dem Erwerb eigener Anteile"},
               %{accountnumber: "69200", accountname: "Einstellung in die Pauschalwertberichtigung auf Forderungen"},
               %{accountnumber: "69220", accountname: "Einstellungen in die steuerliche Rücklage nach § 6b Abs. 3 EStG"},
               %{accountnumber: "69230", accountname: "Einstellung in die Einzelwertberichtigung auf Forderungen"},
               %{accountnumber: "69270", accountname: "Einstellungen in sonstige steuerliche Rücklagen"},
               %{accountnumber: "69280", accountname: "Einstellungen in die Rücklage für Ersatzbeschaffung nach R 6.6 EStR"},
               %{accountnumber: "69290", accountname: "Einstellungen in die steuerliche Rücklage nach § 4g EStG"},
               %{accountnumber: "69300", accountname: "Forderungsverluste (übliche Höhe)"},
               %{accountnumber: "69310", accountname: "Forderungsverluste 7 % USt (übliche Höhe)"},
               %{accountnumber: "69320", accountname: "Forderungsverluste aus steuerfreien EU-Lieferungen (übliche Höhe)"},
               %{accountnumber: "69330", accountname: "Forderungsverluste aus im Inland steuerpflichtigen EU-Lieferungen 7 % USt (übliche Höhe)"},
               %{accountnumber: "69360", accountname: "Forderungsverluste 19 % USt (übliche Höhe)"},
               %{accountnumber: "69380", accountname: "Forderungsverluste aus im Inland steuerpflichtigen EU-Lieferungen 19 % USt (übliche Höhe)"},
               %{accountnumber: "69600", accountname: "Periodenfremde Aufwendungen"},
               %{accountnumber: "69670", accountname: "Sonstige Aufwendungen betriebsfremd und regelmäßig"},
               %{accountnumber: "69680", accountname: "Sonstige nicht abziehbare Aufwendungen"},
               %{accountnumber: "69690", accountname: "Sonstige Aufwendungen unregelmäßig"},
               %{accountnumber: "69700", accountname: "Kalkulatorischer Unternehmerlohn"},
               %{accountnumber: "69720", accountname: "Kalkulatorische Miete und Pacht"},
               %{accountnumber: "69740", accountname: "Kalkulatorische Zinsen"},
               %{accountnumber: "69760", accountname: "Kalkulatorische Abschreibungen"},
               %{accountnumber: "69780", accountname: "Kalkulatorische Wagnisse"},
               %{accountnumber: "69790", accountname: "Kalkulatorischer Lohn für unentgeltliche Mitarbeiter"},
               %{accountnumber: "69800", accountname: "Verrechneter kalkulatorischer Unternehmerlohn"},
               %{accountnumber: "69820", accountname: "Verrechnete kalkulatorische Miete/Pacht"},
               %{accountnumber: "69840", accountname: "Verrechnete kalkulatorische Zinsen"},
               %{accountnumber: "69860", accountname: "Verrechnete kalkulatorische Abschreibungen"},
               %{accountnumber: "69880", accountname: "Verrechnete kalkulatorische Wagnisse"},
               %{accountnumber: "69890", accountname: "Verrechneter kalkulatorischer Lohn für unentgeltliche Mitarbeiter"},
               %{accountnumber: "69900", accountname: "Herstellungskosten"},
               %{accountnumber: "69920", accountname: "Verwaltungskosten"},
               %{accountnumber: "66940", accountname: "Vertriebskosten"},
               %{accountnumber: "69990", accountname: "Gegenkonto zu 6990 0 bis 6998 9"}
             ]}
       ]
     }, %{
       accountclass: "7", accountclassname: "Weitere Erträge und Aufwendungen",
       accountgroups: [
         %{
           accountgroupname: "Erträge aus Beteiligungen",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "70000", accountname: "Erträge aus Beteiligungen"},
               %{accountnumber: "70020", accountname: "Erträge aus typisch stillen Beteiligungen"},
               %{accountnumber: "70030", accountname: "Erträge aus atypisch stillen Beteiligungen"},
               %{accountnumber: "70040", accountname: "Erträge aus Beteiligungen an Personengesellschaften (verbundene Unternehmen), § 9 GewStG bzw. § 18 EStG"},
               %{accountnumber: "70050", accountname: "Erträge aus Anteilen an Kapitalgesellschaften (Beteiligung) § 3 Nr. 40 EStG bzw. § 8b Abs. 1 KStG"},
               %{accountnumber: "70060", accountname: "Erträge aus Anteilen an Kapitalgesellschaften (verbundene Unternehmen) § 3 Nr. 40 EStG bzw. § 8b Abs. 1 KStG"},
               %{accountnumber: "70080", accountname: "Gewinnanteile aus gewerblichen und selbständigen Mitunternehmerschaften, § 9 GewStG bzw. § 18 EStG"},
               %{accountnumber: "70090", accountname: "Erträge aus Beteiligungen an verbundenen Unternehmen"}
             ]},
         %{
           accountgroupname: "Erträge aus anderen Wertpapieren und Ausleihungen des Finanzanlagevermögens",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "70100", accountname: "Erträge aus anderen Wertpapieren und Ausleihungen des Finanzanlagevermögens"},
               %{accountnumber: "70110", accountname: "Erträge aus Ausleihungen des Finanzanlagevermögens"},
               %{accountnumber: "70120", accountname: "Erträge aus Ausleihungen des Finanzanlagevermögens an verbundenen Unternehmen"},
               %{accountnumber: "70130", accountname: "Erträge aus Anteilen an Personengesellschaften (Finanzanlagevermögen)"},
               %{accountnumber: "70140", accountname: "Erträge aus Anteilen an Kapitalgesellschaften (Finanzanlagevermögen) § 3 Nr. 40 EStG bzw. § 8b Abs. 1 und 4 KStG"},
               %{accountnumber: "70150", accountname: "Erträge aus Anteilen an Kapitalgesellschaften (verbundene Unternehmen) § 3 Nr. 40 EStG bzw. § 8b Abs. 1 KStG"},
               %{accountnumber: "70160", accountname: "Erträge aus Anteilen an Personengesellschaften (verbundene Unternehmen)"},
               %{accountnumber: "70170", accountname: "Erträge aus anderen Wertpapieren des Finanzanlagevermögens an Kapitalgesellschaften (verbundene Unternehmen)"},
               %{accountnumber: "70180", accountname: "Erträge aus anderen Wertpapieren des Finanzanlagevermögens an Personengesellschaften (verbundene Unternehmen)"},
               %{accountnumber: "70190", accountname: "Erträge aus anderen Wertpapieren und Ausleihungen des Finanzanlagevermögens aus verbundenen Unternehmen"},
               %{accountnumber: "70200", accountname: "Zins- und Dividendenerträge"},
               %{accountnumber: "70300", accountname: "Erhaltene Ausgleichszahlungen (als außenstehender Aktionär)"}
             ]},
         %{
           accountgroupname: "Sonstige Zinsen und ähnliche Erträge",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "71000", accountname: "Sonstige Zinsen und ähnliche Erträge"},
               %{accountnumber: "71030", accountname: "Erträge aus Anteilen an Kapitalgesellschaften (Umlaufvermögen) § 3 Nr. 40 EStG bzw. § 8b Abs. 1 und 4 KStG"},
               %{accountnumber: "71040", accountname: "Erträge aus Anteilen an Kapitalgesellschaften (verbundene Unternehmen) § 3 Nr. 40 EStG bzw. § 8b Abs. 1 KStG"},
               %{accountnumber: "71050", accountname: "Zinserträge § 233a AO, steuerpflichtig"},
               %{accountnumber: "71060", accountname: "Zinserträge § 233a AO, steuerfrei (Anlage GK KSt)"},
               %{accountnumber: "71070", accountname: "Zinserträge § 233a AO und § 4 Abs. 5b EStG, steuerfrei"},
               %{accountnumber: "71090", accountname: "Sonstige Zinsen und ähnliche Erträge aus verbundenen Unternehmen"},
               %{accountnumber: "71100", accountname: "Sonstige Zinserträge"},
               %{accountnumber: "71150", accountname: "Erträge aus anderen Wertpapieren und Ausleihungen des Umlaufvermögens"},
               %{accountnumber: "71190", accountname: "Sonstige Zinserträge aus verbundenen Unternehmen"},
               %{accountnumber: "71200", accountname: "Zinsähnliche Erträge"},
               %{accountnumber: "71290", accountname: "Zinsähnliche Erträge aus verbundenen Unternehmen"},
               %{accountnumber: "71400", accountname: "Steuerfreie Zinserträge aus der Abzinsung von Rückstellungen"},
               %{accountnumber: "71410", accountname: "Zinserträge aus der Abzinsung von Verbindlichkeiten"},
               %{accountnumber: "71420", accountname: "Zinserträge aus der Abzinsung von Rückstellungen"},
               %{accountnumber: "71430", accountname: "Zinserträge aus der Abzinsung von Pensionsrückstellungen und ähnlichen / vergleichbaren Verpflichtungen"},
               %{accountnumber: "71440", accountname: "Zinserträge aus der Abzinsung von Pensionsrückstellungen und ähnlichen / vergleichbaren Verpflichtungen zur Verrechnung nach § 246 Abs. 2 HGB"},
               %{accountnumber: "71450", accountname: "Erträge aus Vermögensgegenständen zur Verrechnung nach § 246 Abs. 2 HGB"}
             ]},
         %{
           accountgroupname: "Erträge aus Verlustübernahme",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "71900", accountname: "Erträge aus Verlustübernahme"},
               %{accountnumber: "71910", accountname: "Ertragsteuerfreie Einzahlungen zum Verlustausgleich"}
             ]},
         %{
           accountgroupname: "Auf Grund einer Gewinngemeinschaft, eines Gewinn- oder Teilgewinnabführungsvertrags erhaltene Gewinne",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "71920", accountname: "Erhaltene Gewinne auf Grund einer Gewinngemeinschaft"},
               %{accountnumber: "71940", accountname: "Erhaltene Gewinne auf Grund eines Gewinn- oder Teilgewinnabführungsvertrags"}
             ]},
         %{
           accountgroupname: "Abschreibungen auf Finanzanlagen und auf Wertpapiere des Umlaufvermögens",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "72000", accountname: "Abschreibungen auf Finanzanlagen (dauerhaft)"},
               %{accountnumber: "72010", accountname: "Abschreibungen auf Finanzanlagen (nicht dauerhaft)"},
               %{accountnumber: "72040", accountname: "Abschreibungen auf Finanzanlagen § 3 Nr. 40 EStG bzw. § 8b Abs. 3 KStG (dauerhaft)"},
               %{accountnumber: "72070", accountname: "Abschreibungen auf Finanzanlagen - verbundene Unternehmen"},
               %{accountnumber: "72080", accountname: "Aufwendungen auf Grund von Verlustanteilen an gewerblichen und selbständigen Mitunternehmerschaften, § 8 GewStG bzw. § 18 EStG"},
               %{accountnumber: "72100", accountname: "Abschreibungen auf Wertpapiere des Umlaufvermögens"},
               %{accountnumber: "72140", accountname: "Abschreibungen auf Wertpapiere des Umlaufvermögens § 3 Nr. 40 EStG bzw. § 8b Abs. 3 KStG"},
               %{accountnumber: "72170", accountname: "Abschreibungen auf Wertpapiere des Umlaufvermögens - verbundene Unternehmen"},
               %{accountnumber: "72500", accountname: "Abschreibungen auf Finanzanlagen auf Grund § 6b EStG-Rücklage"},
               %{accountnumber: "72550", accountname: "Abschreibungen auf Finanzanlagen auf Grund § 6b EStG-Rücklage, § 3 Nr. 40 EStG bzw. § 8b Abs. 3 KStG"}
             ]},
         %{
           accountgroupname: "Zinsen und ähnliche Aufwendungen",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "73000", accountname: "Zinsen und ähnliche Aufwendungen"},
               %{accountnumber: "73020", accountname: "Steuerlich nicht abzugsfähige andere Nebenleistungen zu Steuern § 4 Abs. 5b EStG"},
               %{accountnumber: "73030", accountname: "Steuerlich abzugsfähige andere Nebenleistungen zu Steuern"},
               %{accountnumber: "73040", accountname: "Steuerlich nicht abzugsfähige andere Nebenleistungen zu Steuern"},
               %{accountnumber: "73050", accountname: "Zinsaufwendungen § 233a AO abzugsfähig"},
               %{accountnumber: "73060", accountname: "Zinsaufwendungen §§ 234 bis 237 AO nicht abzugsfähig"},
               %{accountnumber: "73080", accountname: "Zinsaufwendungen § 233a AO nicht abzugsfähig"},
               %{accountnumber: "73090", accountname: "Zinsaufwendungen an verbundene Unternehmen"},
               %{accountnumber: "73100", accountname: "Zinsaufwendungen für kurzfristige Verbindlichkeiten"},
               %{accountnumber: "73110", accountname: "Zinsaufwendungen §§ 234 bis 237 AO abzugsfähig"},
               %{accountnumber: "73160", accountname: "Zinsen für Gesellschafterdarlehen"},
               %{accountnumber: "73170", accountname: "Zinsen an Gesellschafter mit einer Beteiligung von mehr als 25 % bzw. diesen nahe stehende Personen"},
               %{accountnumber: "73180", accountname: "Zinsen auf Kontokorrentkonten"},
               %{accountnumber: "73190", accountname: "Zinsaufwendungen für kurzfristige Verbindlichkeiten an verbundene Unternehmen"},
               %{accountnumber: "73200", accountname: "Zinsaufwendungen für langfristige Verbindlichkeiten"},
               %{accountnumber: "73230", accountname: "Abschreibungen auf ein Agio oder Disagio/Damnum zur Finanzierung"},
               %{accountnumber: "73240", accountname: "Abschreibungen auf ein Agio oder Disagio/Damnum zur Finanzierung des Anlagevermögens"},
               %{accountnumber: "73250", accountname: "Zinsaufwendungen für Gebäude, die zum Betriebsvermögen gehören"},
               %{accountnumber: "73260", accountname: "Zinsen zur Finanzierung des Anlagevermögens"},
               %{accountnumber: "73270", accountname: "Renten und dauernde Lasten"},
               %{accountnumber: "73290", accountname: "Zinsaufwendungen für langfristige Verbindlichkeiten an verbundene Unternehmen"},
               %{accountnumber: "73300", accountname: "Zinsähnliche Aufwendungen"},
               %{accountnumber: "73390", accountname: "Zinsähnliche Aufwendungen an verbundene Unternehmen"},
               %{accountnumber: "73500", accountname: "Zinsen und ähnliche Aufwendungen §§ 3 Nr. 40 und 3c EStG bzw. § 8b Abs. 1 und Abs. 4 KStG,"},
               %{accountnumber: "73510", accountname: "Zinsen und ähnliche Aufwendungen an verbundene Unternehmen §§ 3 Nr. 40 und 3c EStG bzw. § 8b Abs. 1 KStG,"},
               %{accountnumber: "73550", accountname: "Kreditprovisionen und Verwaltungskostenbeiträge"},
               %{accountnumber: "73600", accountname: "Zinsanteil der Zuführungen zu Pensionsrückstellungen"},
               %{accountnumber: "73610", accountname: "Zinsaufwendungen aus der Abzinsung von Verbindlichkeiten"},
               %{accountnumber: "73620", accountname: "Zinsaufwendungen aus der Abzinsung von Rückstellungen"},
               %{accountnumber: "73630", accountname: "Zinsaufwendungen aus der Abzinsung von Pensionsrückstellungen und ähnlichen / vergleichbaren Verpflichtungen"},
               %{accountnumber: "73640", accountname: "Zinsaufwendungen aus der Abzinsung von Pensionsrückstellungen und ähnlichen / vergleichbaren Verpflichtungen zur Verrechnung nach § 246 Abs. 2 HGB"},
               %{accountnumber: "73650", accountname: "Aufwendungen aus Vermögensgegenständen zur Verrechnung nach § 246 Abs. 2 HGB"},
               %{accountnumber: "73660", accountname: "Steuerlich nicht abzugsfähige Zinsaufwendungen aus der Abzinsung von Rückstellungen"}
             ]},
         %{
           accountgroupname: "Aufwendungen aus Verlustübernahmen (Mutter)",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "73900", accountname: "Aufwendungen aus Verlustübernahme"}
             ]},
         %{
           accountgroupname: "aufgrund einer Gewinngemeinschaft, eines Gewinnabführungs- oder Teilgewinnabführungsvertrags abgeführte Gewinne",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "73920", accountname: "Abgeführte Gewinne auf Grund einer Gewinngemeinschaft"},
               %{accountnumber: "73940", accountname: "Abgeführte Gewinne auf Grund eines Gewinn- oder Teilgewinnabführungsvertrags"},
             ]},
         %{
           accountgroupname: "Aufgrund einer Gewinngemeinschaft, eines Gewinnabführungs- oder Teilgewinnabführungsvertrags abgeführte Gewinne",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "73980", accountname: "Abgeführte Gewinnanteile (Soll) / ausgeglichene Verlustanteile (Haben) bei atypisch stiller Beteiligung"},
               %{accountnumber: "73990", accountname: "Abgeführte Gewinnanteile (Soll) / ausgeglichene Verlustanteile (Haben) bei typisch stiller Beteiligung § 8 GewStG"}
             ]},
         %{
           accountgroupname: "Sonstige betriebliche Erträge",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "74510", accountname: "Erträge durch Verschmelzung und Umwandlung"},
               %{accountnumber: "74600", accountname: "Erträge aus der Anwendung von Übergangsvorschriften"},
               %{accountnumber: "74640", accountname: "Erträge aus der Anwendung von Übergangsvorschriften (latente Steuern)"}
             ]},
         %{
           accountgroupname: "Sonstige betriebliche Aufwendungen",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "75510", accountname: "Verluste durch Verschmelzung und Umwandlung"},
               %{accountnumber: "75530", accountname: "Aufwendungen für Restrukturierungs- und Sanierungsmaßnahmen"},
               %{accountnumber: "75600", accountname: "Aufwendungen aus der Anwendung von Übergangsvorschriften"},
               %{accountnumber: "75610", accountname: "Aufwendungen aus der Anwendung von Übergangsvorschriften (Pensionsrückstellungen)"},
               %{accountnumber: "75630", accountname: "Aufwendungen aus der Anwendung von Übergangsvorschriften (Latente Steuern)"}
             ]},
         %{
           accountgroupname: "Steuern vom Einkommen und vom Ertrag",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "76000", accountname: "Körperschaftsteuer"},
               %{accountnumber: "76030", accountname: "Körperschaftsteuer für Vorjahre"},
               %{accountnumber: "76040", accountname: "Körperschaftsteuererstattungen für Vorjahre"},
               %{accountnumber: "76070", accountname: "Solidaritätszuschlagerstattungen für Vorjahre"},
               %{accountnumber: "76080", accountname: "Solidaritätszuschlag"},
               %{accountnumber: "76090", accountname: "Solidaritätszuschlag für Vorjahre"},
               %{accountnumber: "76100", accountname: "Gewerbesteuer"},
               %{accountnumber: "76300", accountname: "Kapitalertragsteuer 25 %"},
               %{accountnumber: "76380", accountname: "Ausländische Steuer auf im Inland steuerfreie DBA-Einkünfte"},
               %{accountnumber: "76410", accountname: "Gewerbesteuernachzahlungen für Vorjahre nach § 4 Abs. 5b EStG"},
               %{accountnumber: "76450", accountname: "Aufwendungen aus der Zuführung und Auflösung von latenten Steuern"},
               %{accountnumber: "76460", accountname: "Aufwendungen aus der Zuführung zu Steuerrückstellungen für Steuerstundung (BStBK)"}
             ]},
                      %{
           accountgroupname: "Steuern vom Einkommen und vom Ertrag",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "76310", accountname: "Kapitalertragsteuererstattung"},
               %{accountnumber: "76330", accountname: "Anrechenbarer Solidaritätszuschlag auf Kapitalertragsteuer 25 %"},
               %{accountnumber: "76390", accountname: "Anrechnung / Abzug ausländische Quellensteuer"},
               %{accountnumber: "76410", accountname: "Gewerbesteuererstattungen für Vorjahre nach § 4 Abs. 5b EStG"},
               %{accountnumber: "76430", accountname: "Erträge aus der Auflösung von Gewerbesteuerrückstellungen nach § 4 Abs. 5b EStG"},
               %{accountnumber: "76480", accountname: "Erträge aus der Auflösung von Steuerrückstellungen für Steuerstundung (BStBK)"},
               %{accountnumber: "76490", accountname: "Erträge aus der Zuführung und Auflösung von latenten Steuern"}
             ]},
         %{
           accountgroupname: "Sonstige Steuern",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "76500", accountname: "Sonstige Betriebssteuern"},
               %{accountnumber: "76750", accountname: "Verbrauchsteuer (sonstige Steuern)"},
               %{accountnumber: "76780", accountname: "Ökosteuer"},
               %{accountnumber: "76800", accountname: "Grundsteuer"},
               %{accountnumber: "76850", accountname: "Kfz-Steuer"},
               %{accountnumber: "76900", accountname: "Steuernachzahlungen Vorjahre für sonstige Steuern"}
             ]},
         %{
           accountgroupname: "Sonstige Steuern",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "76920", accountname: "Steuererstattungen Vorjahre für sonstige Steuern"},
               %{accountnumber: "76940", accountname: "Erträge aus der Auflösung von Rückstellungen für sonstige Steuern"}
             ]},
         %{
           accountgroupname: "Ergebnisvorträge aus dem Vorjahr",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "77000", accountname: "Gewinnvortrag / Ergebnisvortrag nach Verwendung"}
             ]},
         %{
           accountgroupname: "Ergebnisvorträge aus dem Vorjahr (Vereine /Stiftungen) / Verlustvortrag aus dem Vorjahr (gGmbH)",
           accounttypecode: "aufwand",
           accounts: [
               %{accountnumber: "77200", accountname: "Verlustvortrag / Ergebnisvortrag nach Verwendung"}
             ]},
         %{
           accountgroupname: "Entnahme aus der Kapitalrücklage (gGmbH / Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77300", accountname: "Entnahmen aus der Kapitalrücklage"}
             ]},
         %{
           accountgroupname: "Entnahmen aus der gesetzlichen Rücklage",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77320", accountname: "Entnahmen aus der gesetzlichen Rücklage"}
             ]},
         %{
           accountgroupname: "Entnahmen aus der Rücklage für Anteile an einem herrschenden oder mehrheitlich beteiligten Unternehmen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77340", accountname: "Entnahmen aus der Rücklage für Anteile an einem herrschenden oder mehrheitlich beteiligten Unternehmen"}
             ]},
         %{
           accountgroupname: "Entnahmen aus satzungsmäßigen Rücklagen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77360", accountname: "Entnahmen aus satzungsmäßigen Rücklagen"}
             ]},
         %{
           accountgroupname: "Entnahmen aus anderen Gewinnrücklagen (gGmbH)/ sonstigen Ergebnisrücklagen (Vereine/Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77380", accountname: "Entnahmen aus anderen Gewinnrücklagen / aus sonstigen Ergebnisrücklagen"}
             ]},
         %{
           accountgroupname: "Ertrag aus Kapitalherabsetzung",
           accounttypecode: "ertrag",
           accounts: [
               %{accountnumber: "77400", accountname: "Erträge aus Kapitalherabsetzung"}
             ]},
         %{
           accountgroupname: "Entnahmen aus anderen Gewinnrücklagen (gGmbH) / Verminderung des Vereins-/Stiftungskapitals aus realisierten Vermögensumschichtungen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77450", accountname: "Verminderung des Kapitals aus realisierten Vermögensumschichtungen"}
             ]},
         %{
           accountgroupname: "Entnahme aus dem Vereinskapital / den sonstigen nicht zeitnah zu verwendenden Mitteln (Stiftungen) / der Kapitalrücklage (gGmbH)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77470", accountname: "Entnahmen aus den sonstigen nicht zeitnah zu verwendenden Mitteln / dem Vereinskapital"}
             ]},
          %{
           accountgroupname: "Entnahmen aus anderen Gewinnrücklagen (gGmbH) / der gebundenen Rücklage (Vereine/Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77490", accountname: "Entnahmen aus gebundenen Rücklagen nach § 62 Abs. 1 Nr. 1 u. 2 AO"}
             ]},
          %{
           accountgroupname: "Entnahmen aus anderen Gewinnrücklagen (gGmbH) / der freien Rücklage (Vereine / Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77510", accountname: "Entnahmen aus freien Rücklagen nach § 62 Abs. 1 Nr. 3 AO"}
             ]},
          %{
           accountgroupname: "Entnahmen aus anderen Gewinnrücklagen (gGmbH) / der Rücklage zum Erwerb von Gesellschaftsrechten (Vereine / Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77530", accountname: "Entnahmen aus Rücklagen zum Erwerb von Gesellschaftsrechten nach § 62 Abs. 1 Nr. 4 AO"}
             ]},
          %{
           accountgroupname: "Verminderung des nutzungsgebundenen Kapitals",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77550", accountname: "Verminderung des nutzungsgebundenen Kapitals"}
             ]},
          %{
           accountgroupname: "Entnahmen aus der Kapitalerhaltungsrücklage (Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77570", accountname: "Entnahmen aus der Kapitalerhaltungsrücklage"}
             ]},
          %{
           accountgroupname: "Entnahmen aus der Ansparrücklage (Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77590", accountname: "Entnahmen aus der Ansparrücklage nach § 62 Abs. 4 AO"}
             ]},
          %{
           accountgroupname: "Einstellung in die Kapitalrücklage (gGmbH / Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77600", accountname: "Einstellungen in die Kapitalrücklage nach den Vorschriften über die vereinfachte Kapitalherabsetzung"}
             ]},
          %{
           accountgroupname: "Einstellungen in die gesetzlichen Rücklage",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77620", accountname: "Einstellungen in die gesetzliche Rücklage"}
             ]},
          %{
           accountgroupname: "Einstellungen in die Rücklage für Anteile an einem herrschenden oder mehrheitlich beteiligten Unternehmen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77640", accountname: "Einstellungen in die Rücklage für Anteile an einem herrschenden oder mehrheitlich beteiligten Unternehmen"}
             ]},
          %{
           accountgroupname: "Einstellungen in die satzungsmäßigen Rücklagen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77660", accountname: "Einstellungen in satzungsmäßige Rücklagen"}
             ]},
          %{
           accountgroupname: "Einstellungen in andere Gewinnrücklagen (gGmbH) / sonstigen Ergebnisrücklagen (Vereine/Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77680", accountname: "Einstellungen in andere Gewinnrücklagen / sonstige Ergebnisrücklagen"}
             ]},
          %{
           accountgroupname: "Steuerliches Mehr-/Minderergebnis lfd. Jahr (steuerlicher Ausgleichsposten)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77690", accountname: "Änderung steuerlicher Ausgleichsposten (Körperschaften)"}
             ]},
          %{
           accountgroupname: "Einstellung in andere Gewinnrücklagen (gGmbH) / Erhöhung des Vereins-/Stiftungskapitals aus realisierten Vermögensumschichtungen",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77750", accountname: "Erhöhung des Kapitals aus Vermögensumschichtungen"}
             ]},
          %{
           accountgroupname: "Einstellung in das Vereinskapital / die sonstigen nicht zeitnah zu verwendenden Mittel (Stiftung) / die Kapitalrücklage (gGmbH)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77770", accountname: "Einstellungen in die sonstigen nicht zeitnah zu verwendenden Mittel / das Vereinskapital"}
             ]},
          %{
           accountgroupname: "Einstellung in anderen Gewinnrücklagen (gGmbH) / die gebundene Rücklage(Vereine/Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77790", accountname: "Einstellungen in gebundene Rücklagen nach § 62 Abs. 1 Nr. 1 u. 2 AO"}
             ]},
          %{
           accountgroupname: "Einstellung in andere Gewinnrücklagen (gGmbH) / die freie Rücklage (Vereine/Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77810", accountname: "Einstellungen in freie Rücklagen nach § 62 Abs. 1 Nr. 3 AO"}
             ]},
          %{
           accountgroupname: "Einstellung in andere Gewinnrücklagen (gGmbH) / die Rücklage zum Erwerb von Gesellschaftsrechten (Vereine / Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77830", accountname: "Einstellungen in Rücklagen zum Erwerb von Gesellschaftsrechten nach § 62 Abs. 1 Nr. 4 AO"}
             ]},
          %{
           accountgroupname: "Erhöhung des nutzungsgebundenen Kapitals",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77850", accountname: "Erhöhung des nutzungsgebundenen Kapitals"}
             ]},
          %{
           accountgroupname: "Einstellungen in die Kapitalerhaltungsrücklage (Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77870", accountname: "Einstellungen in die Kapitalerhaltungsrücklage"}
             ]},
          %{
           accountgroupname: "Einstellungen in die Ansparrücklage (Stiftungen)",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77890", accountname: "Einstellungen in die Ansparrücklage nach § 62 Abs. 4 AO"}
             ]},
          %{
           accountgroupname: "Ausschüttung",
           accounttypecode: "passiv",
           accounts: [
               %{accountnumber: "77900", accountname: "Vorabausschüttung"}
             ]}
           ]
     }, %{
       accountclass: "9", accountclassname: "Vortrags, Kapital-, Korrekturkonten",
       accountgroups: [
         %{
           accountgroupname: "Saldenvorträge",
           accounttypecode: "neutral",
             accounts: [
               %{accountnumber: "90000", accountname: "Saldenvorträge, Sachkonten"},
               %{accountnumber: "90080", accountname: "Saldenvorträge, Debitoren"},
               %{accountnumber: "90090", accountname: "Saldenvorträge, Kreditoren"},
               %{accountnumber: "90500", accountname: "Offene Posten aus 2020"},
               %{accountnumber: "90510", accountname: "Offene Posten aus 2021"},
               %{accountnumber: "90520", accountname: "Offene Posten aus 2022"},
               %{accountnumber: "90530", accountname: "Offene Posten aus 2023"},
               %{accountnumber: "90540", accountname: "Offene Posten aus 2024"},
               %{accountnumber: "90550", accountname: "Offene Posten aus 2025"},
               %{accountnumber: "90700", accountname: "Offene Posten aus 2000"},
               %{accountnumber: "90710", accountname: "Offene Posten aus 2001"},
               %{accountnumber: "90720", accountname: "Offene Posten aus 2002"},
               %{accountnumber: "90730", accountname: "Offene Posten aus 2003"},
               %{accountnumber: "90740", accountname: "Offene Posten aus 2004"},
               %{accountnumber: "90750", accountname: "Offene Posten aus 2005"},
               %{accountnumber: "90760", accountname: "Offene Posten aus 2006"},
               %{accountnumber: "90770", accountname: "Offene Posten aus 2007"},
               %{accountnumber: "90780", accountname: "Offene Posten aus 2008"},
               %{accountnumber: "90790", accountname: "Offene Posten aus 2009"},
               %{accountnumber: "90800", accountname: "Offene Posten aus 2010"},
               %{accountnumber: "90810", accountname: "Offene Posten aus 2011"},
               %{accountnumber: "90820", accountname: "Offene Posten aus 2012"},
               %{accountnumber: "90830", accountname: "Offene Posten aus 2013"},
               %{accountnumber: "90840", accountname: "Offene Posten aus 2014"},
               %{accountnumber: "90850", accountname: "Offene Posten aus 2015"},
               %{accountnumber: "90860", accountname: "Offene Posten aus 2016"},
               %{accountnumber: "90870", accountname: "Offene Posten aus 2017"},
               %{accountnumber: "90880", accountname: "Offene Posten aus 2018"},
               %{accountnumber: "90890", accountname: "Offene Posten aus 2019"},
               %{accountnumber: "90900", accountname: "Summenvortragskonto"}
             ]},
                   %{
           accountgroupname: "Verbindlichkeiten aus Lieferungen und Leistungen",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "92920", accountname: "Statistisches Konto Fremdgeld"}
             ]},
                   %{
           accountgroupname: "Sonstige Verbindlichkeiten",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "92930", accountname: "Gegenkonto zu 92920"}
             ]},
                   %{
           accountgroupname: "Einlagen stiller Gesellschafter",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "92950", accountname: "Einlagen atypisch stiller Gesellschafter"}
             ]},
                   %{
           accountgroupname: "steuerlicher Ausgleichsposten",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "92970", accountname: "Steuerlicher Ausgleichsposten (Körperschaften)"}
             ]},
                   %{
           accountgroupname: "Forderungen aus Lieferungen und Leistungen",
           accounttypecode: "aktiv",
             accounts: [
               %{accountnumber: "99400", accountname: "Bewertungskorrektur zu Forderungen aus Lieferungen und Leistungen (Währungsumrechnung)"}
             ]},
                   %{
           accountgroupname: "Sonstige Verbindlichkeiten",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "99410", accountname: "Bewertungskorrektur zu sonstigen Verbindlichkeiten (Währungsumrechnung)"}
             ]},
                   %{
           accountgroupname: "Kassenbestand, Bundesbankguthaben, Guthaben bei Kreditinstituten und Schecks",
           accounttypecode: "aktiv",
             accounts: [
               %{accountnumber: "99420", accountname: "Bewertungskorrektur zu Guthaben bei Kreditinstituten (Bewertung Finanzmittelfonds)"}
             ]},
                   %{
           accountgroupname: "Verbindlichkeiten gegenüber Kreditinstituten",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "99430", accountname: "Bewertungskorrektur zu Verbindlichkeiten gegenüber Kreditinstituten (Bewertung Finanzmittelfonds)"}
             ]},
                   %{
           accountgroupname: "Verbindlichkeiten aus Lieferungen und Leistungen",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "99440", accountname: "Bewertungskorrektur zu Verbindlichkeiten aus Lieferungen und Leistungen (Währungsumrechnung)"}
             ]},
                   %{
           accountgroupname: "Sonstige Vermögensgegenstände",
           accounttypecode: "aktiv",
             accounts: [
               %{accountnumber: "99450", accountname: "Bewertungskorrektur zu sonstigen Vermögensgegenständen (Währungsumrechnung)"}
             ]},
                   %{
           accountgroupname: "Forderungen gegen verbundene Unternehmen",
           accounttypecode: "aktiv",
             accounts: [
               %{accountnumber: "99460", accountname: "Bewertungskorrektur zu Forderungen gegen verbundene Unternehmen"}
             ]},
                   %{
           accountgroupname: "Forderungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht",
           accounttypecode: "aktiv",
             accounts: [
               %{accountnumber: "99470", accountname: "Bewertungskorrektur zu Forderungen gegen Unternehmen, mit denen ein Beteiligungsverhältnis besteht"}
             ]},
                   %{
           accountgroupname: "Verbindlichkeiten gegenüber verbundenen Unternehmen",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "99480", accountname: "Bewertungskorrektur zu Verbindlichkeiten gegenüber verbundenen Unternehmen"}
             ]},
                   %{
           accountgroupname: "Verbindlichkeiten gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht",
           accounttypecode: "passiv",
             accounts: [
               %{accountnumber: "99490", accountname: "Bewertungskorrektur zu Verbindlichkeiten gegenüber Unternehmen, mit denen ein Beteiligungsverhältnis besteht"}
             ]}
           ]
     }
  ]

# 3. Verarbeitung
defmodule Sportyweb.SKRHelper do
  def create_skr42(club, accounting_data) do
    Enum.each(accounting_data, fn accountclass_data ->
      # 1. Klasse sicher abrufen oder erstellen
      accountclass =
        Repo.get_by(Accountclass, club_id: club.id, accountclassnumber: accountclass_data.accountclass) ||
        Repo.insert!(%Accountclass{
          accountclassnumber: accountclass_data.accountclass,
          accountclassname: accountclass_data.accountclassname,
          club_id: club.id
        })

      Enum.each(accountclass_data.accountgroups, fn accountgroup_data ->
        accountgroup =
          Repo.get_by(Accountgroup, club_id: club.id, accountgroupname: accountgroup_data.accountgroupname) ||
          Repo.insert!(%Accountgroup{
            accountgroupname: accountgroup_data.accountgroupname,
            club_id: club.id
          })

          Enum.each(accountgroup_data.accounts, fn account_data ->

            unless Repo.get_by(Account, club_id: club.id, accountnumber: account_data.accountnumber) do

              # Wir bauen eine Map mit ALLEN benötigten Daten und IDs
                account_attrs = Map.merge(account_data, %{
                  accountclass_id: accountclass.id, # Zugriff auf äußere Schleife Accountclasses
                  accountgroup_id: accountgroup.id, # Zugriff auf äußere Schleife Accountgroups
                  accounttypecode: accountgroup_data.accounttypecode, # Zugriff auf Accounttypecode der äußeren Schleife Accountgroups
                  club_id: club.id # Zugriff auf Club.id aus dem Aufruf
                })
                |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)

              %Account{}
              |> Account.changeset(account_attrs)
              |> Repo.insert!()
            end

          end)

      end)
    end)
  end
end

#Schritt 4: Wir erzeugen die Datenbankeinträge durch den Methodenaufruf.
Sportyweb.SKRHelper.create_skr42(club_1, accounting_data)
Sportyweb.SKRHelper.create_skr42(club_2, accounting_data)
Sportyweb.SKRHelper.create_skr42(club_3, accounting_data)
Sportyweb.SKRHelper.create_skr42(club_4, accounting_data)
Sportyweb.SKRHelper.create_skr42(testclub, accounting_data)


# ============================================================
# Buchungsperiode 2026 anlegen
# ============================================================
period_2025 = Repo.insert!(%Sportyweb.Accounting.AccountingPeriod{
  club_id: club_1.id,
  name: "2025",
  starts_on: ~D[2025-01-01],
  ends_on: ~D[2025-12-31],
  status: :open
})

  period_2026 = Repo.insert!(%Sportyweb.Accounting.AccountingPeriod{
  club_id: club_1.id,
  name: "2026",
  starts_on: ~D[2026-01-01],
  ends_on: ~D[2026-12-31],
  status: :open
})

#############################################################
# Adds Accounting_Transactions as examples
#

bank = Repo.get_by!(Sportyweb.Accounting.Account, accountnumber: "18000", club_id: club_1.id)
mitgliedsbeitraege = Repo.get_by!(Sportyweb.Accounting.Account, accountnumber: "40000", club_id: club_1.id)
übungsleiterpauschalen = Repo.get_by!(Sportyweb.Accounting.Account, accountnumber: "60040", club_id: club_1.id)
spenden = Repo.get_by!(Sportyweb.Accounting.Account, accountnumber: "40400", club_id: club_1.id)
zuschuesse = Repo.get_by!(Sportyweb.Accounting.Account, accountnumber: "49750", club_id: club_1.id)
sportveranstaltungen = Repo.get_by!(Sportyweb.Accounting.Account, accountnumber: "43050", club_id: club_1.id)
raumkosten = Repo.get_by!(Sportyweb.Accounting.Account, accountnumber: "63090", club_id: club_1.id)
sportmaterial = Repo.get_by!(Sportyweb.Accounting.Account, accountnumber: "68450", club_id: club_1.id)

#
# Schritt 1: Buchungsdaten erfassen:

accounting_transaction_data = [
  # ============================================================
  # Mitgliedsbeiträge
  # ============================================================
  {
    %{
      description: "Mitgliedsbeitrag Januar 2026",
      reference: "MB-2026-001",
      document_date: ~D[2026-03-01],
      status: :posted,
      posted_at: ~U[2026-03-01 10:00:00Z]
    },
    [
      %{account_id: bank.id, amount: "2400", description: "Eingang Mitgliedsbeitrag"},
      %{account_id: mitgliedsbeitraege.id, amount: "-2400", description: "Mitgliedsbeitrag Ertrag"}
    ]
  },
    {
    %{
      description: "Mitgliedsbeitrag Februar 2026",
      reference: "MB-2026-002",
      document_date: ~D[2026-03-01],
      status: :posted,
      posted_at: ~U[2026-03-01 10:00:00Z]
    },
    [
      %{account_id: bank.id, amount: "2400", description: "Eingang Mitgliedsbeitrag"},
      %{account_id: mitgliedsbeitraege.id, amount: "-2400", description: "Mitgliedsbeitrag Ertrag"}
    ]
  },

  {
    %{
      description: "Mitgliedsbeitrag März 2026",
      reference: "MB-2026-003",
      document_date: ~D[2026-03-01],
      status: :posted,
      posted_at: ~U[2026-03-01 10:00:00Z]
    },
    [
      %{account_id: bank.id, amount: "2400", description: "Eingang Mitgliedsbeitrag"},
      %{account_id: mitgliedsbeitraege.id, amount: "-2400", description: "Mitgliedsbeitrag Ertrag"}
    ]
  },

  # ============================================================
  # Spenden
  # ============================================================

  {
    %{
      description: "Spende Stadtwerke GmbH",
      reference: "SP-2026-001",
      document_date: ~D[2026-01-15],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-01-15 09:00:00Z]
    },
    [
      %{account_id: bank.id, amount: "1000", description: "Spendeneingang Stadtwerke"},
      %{account_id: spenden.id, amount: "-1000", description: "Spendenertrag"}
    ]
  },

  {
    %{
      description: "Spende Privatperson Müller",
      reference: "SP-2026-002",
      document_date: ~D[2026-02-10],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-02-10 11:00:00Z]
    },
    [
      %{account_id: bank.id, amount: "250", description: "Spendeneingang Müller"},
      %{account_id: spenden.id, amount: "-250", description: "Spendenertrag"}
    ]
  },

  # ============================================================
  # Zuschüsse
  # ============================================================
  {
    %{
      description: "Zuschuss Landessportbund 2026",
      reference: "ZU-2026-001",
      document_date: ~D[2026-01-20],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-01-20 14:00:00Z]
    },
    [
      %{account_id: bank.id, amount: "5000",  description: "Eingang Förderung LSB"},
      %{account_id: zuschuesse.id, amount: "-5000", description: "Zuschussertrag LSB"}
    ]
  },

  {
    %{
      description: "Kommunaler Sportförderungszuschuss",
      reference: "ZU-2026-002",
      document_date: ~D[2026-02-01],
      status: :pending,
      sphere: :ideal,
    },
    [
      %{account_id: bank.id, amount: "2500", description: "Eingang Stadtförderung"},
      %{account_id: zuschuesse.id, amount: "-2500", description: "Kommunaler Zuschuss"}
    ]
  },

  # ============================================================
  # Sportveranstaltungen
  # ============================================================
  {
    %{
      description: "Einnahmen Heimspiel 08.02.2026",
      reference: "VE-2026-001",
      document_date: ~D[2026-02-08],
      status: :posted,
      sphere: :purpose_related,
      posted_at: ~U[2026-02-08 20:00:00Z]
    },
    [
      %{account_id: bank.id, amount: "480", description: "Eintrittsgelder Heimspiel"},
      %{account_id: sportveranstaltungen.id, amount: "-480", description: "Veranstaltungsertrag"}
    ]
  },

  {
    %{
      description: "Einnahmen Turnier 15.03.2026",
      reference: "VE-2026-002",
      document_date: ~D[2026-03-15],
      status: :posted,
      sphere: :purpose_related,
      posted_at: ~U[2026-03-15 18:00:00Z]
    },
    [
      %{account_id: bank.id, amount: "1200", description: "Startgelder und Eintritt"},
      %{account_id: sportveranstaltungen.id, amount: "-1200", description: "Turnierertrag"}
    ]
  },

  # ============================================================
  # Übungsleiterpauschalen
  # ============================================================
  {
    %{
      description: "Übungsleiterpauschalen Januar 2026",
      reference: "AW-2026-001",
      document_date: ~D[2026-01-31],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-01-31 16:00:00Z]
    },
    [
      %{account_id: übungsleiterpauschalen.id, amount: "840", description: "Pauschalen 7 Übungsleiter"},
      %{account_id: bank.id, amount: "-840", description: "Bankabgang Übungsleiter"}
    ]
  },

  {
    %{
      description: "Übungsleiterpauschalen Februar 2026",
      reference: "AW-2026-002",
      document_date: ~D[2026-02-28],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-02-28 16:00:00Z]
    },
    [
      %{account_id: übungsleiterpauschalen.id, amount: "840",  description: "Pauschalen 7 Übungsleiter"},
      %{account_id: bank.id, amount: "-840", description: "Bankabgang Übungsleiter"}
    ]
  },

  {
    %{
      description: "Übungsleiterpauschalen März 2026",
      reference: "AW-2026-003",
      document_date: ~D[2026-03-01],
      status: :pending,
      sphere: :ideal,
    },
    [
      %{account_id: übungsleiterpauschalen.id, amount: "840",  description: "Pauschalen 7 Übungsleiter"},
      %{account_id: bank.id, amount: "-840", description: "Bankabgang Übungsleiter"}
    ]
  },

  # ============================================================
  # Raumkosten
  # ============================================================
  {
    %{
      description: "Hallenmiete Januar 2026",
      reference: "RK-2026-001",
      document_date: ~D[2026-01-31],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-01-31 12:00:00Z]
    },
    [
      %{account_id: raumkosten.id, amount: "950",  description: "Hallenmiete Januar"},
      %{account_id: bank.id, amount: "-950", description: "Bankabgang Miete"}
    ]
  },

  {
    %{
      description: "Hallenmiete Februar 2026",
      reference: "RK-2026-002",
      document_date: ~D[2026-02-28],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-02-28 12:00:00Z]
    },
    [
      %{account_id: raumkosten.id, amount: "950", description: "Hallenmiete Februar"},
      %{account_id: bank.id, amount: "-950", description: "Bankabgang Miete"}
    ]
  },

  {
    %{
      description: "Hallenmiete März 2026",
      reference: "RK-2026-003",
      document_date: ~D[2026-03-01],
      status: :pending,
      sphere: :ideal,
    },
    [
      %{account_id: raumkosten.id, amount: "950", description: "Hallenmiete März"},
      %{account_id: bank.id, amount: "-950", description: "Bankabgang Miete"}
    ]
  },

  {
    %{
      description: "Hallenmiete Turnier 15.03.2026",
      reference: "VE-2026-002",
      document_date: ~D[2026-03-01],
      status: :pending,
      sphere: :purpose_related,
    },
    [
      %{account_id: raumkosten.id, amount: "150", description: "Hallenmiete März"},
      %{account_id: bank.id, amount: "-150", description: "Bankabgang Miete"}
    ]
  },

  # ============================================================
  # Sportmaterial
  # ============================================================
  {
    %{
      description: "Trainingsmaterial Herbst 2025",
      reference: "SM-2025-001",
      document_date: ~D[2026-01-10],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-01-10 09:00:00Z]
    },
    [
      %{account_id: sportmaterial.id, amount: "620", description: "Bälle und Trainingsequipment"},
      %{account_id: bank.id, amount: "-620", description: "Bankabgang Material"}
    ]
  },

  {
    %{
      description: "Trikots Saison 2026",
      reference: "SM-2026-001",
      document_date: ~D[2026-02-20],
      status: :posted,
      sphere: :ideal,
      posted_at: ~U[2026-02-20 10:00:00Z]
    },
    [
      %{account_id: sportmaterial.id, amount: "1400", description: "Trikotsatz 1. Mannschaft"},
      %{account_id: bank.id, amount: "-1400", description: "Bankabgang Trikots"}
    ]
  },

  {
    %{
      description: "Ersatzmaterial Frühjahr 2026",
      reference: "SM-2026-002",
      document_date: ~D[2026-04-01],
      status: :draft,
      sphere: :ideal,
    },
    [
      %{account_id: sportmaterial.id, amount: "380", description: "Ersatzmaterial diverse"},
      %{account_id: bank.id, amount: "-380", description: "Bankabgang Material"}
    ]
  }

]

# Schritt 2: Modul zur Verarbeitung der Datenstruktur

defmodule Seeds.Accounting do
  def create_transaction(club_id, period_id, attrs, entries) do
    entry_attrs =
      Enum.map(entries, fn entry ->
        %{
          "club_id" => club_id,
          "account_id" => entry.account_id,
          "amount_input" => entry.amount,
          "description" => Map.get(entry, :description, "")
        }
      end)

    transaction_attrs = %{
      "club_id" => club_id,
      "accounting_period_id" => period_id,
      "description" => attrs.description,
      "document_date" => Map.get(attrs, :document_date, Date.utc_today()),
      "reference" => Map.get(attrs, :reference, ""),
      "status" => to_string(Map.get(attrs, :status, :draft)),
      "sphere" => to_string(Map.get(attrs, :sphere, :ideal)),
      "posted_at" => Map.get(attrs, :posted_at, nil),
      "entries" => entry_attrs
    }

    case Sportyweb.Accounting.create_accounting_transaction(transaction_attrs) do
      {:ok, _transaction} -> :ok
      {:error, changeset} -> IO.inspect(changeset, label: "Fehler beim Erstellen der Transaktion")
    end
  end

  def create_transactions(club_id, period_id, definitions) do
    Enum.each(definitions, fn {attrs, entries} ->
      create_transaction(club_id, period_id, attrs, entries)
    end)
  end

end

# Schritt 3: Aufruf des Moduls zusammen mit der Datenstruktur

Seeds.Accounting.create_transactions(club_1.id, period_2026.id, accounting_transaction_data)
