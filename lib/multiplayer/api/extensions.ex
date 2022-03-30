defmodule Multiplayer.Api.Extensions do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, only: [:type, :inserted_at, :updated_at, :settings]}
  schema "extensions" do
    field(:type, :string)
    field(:settings, :map)
    belongs_to(:tenant, Multiplayer.Api.Tenant, foreign_key: :tenant_external_id, type: :string)
    timestamps()
  end

  def changeset(extension, attrs) do
    {attrs1, required_settings} =
      case attrs["type"] do
        nil ->
          {attrs, []}

        type ->
          module = Multiplayer.extension_module(type)

          settings =
            apply(module, :default_settings, [])
            |> Map.merge(attrs["settings"])

          {
            %{attrs | "settings" => settings},
            apply(module, :required_settings, [])
          }
      end

    extension
    |> cast(attrs1, [:type, :tenant_external_id, :settings])
    |> validate_required([:type, :settings])
    |> validate_required_settings(required_settings)
  end

  def validate_required_settings(changeset, required) do
    validate_change(changeset, :settings, fn
      _, value ->
        Enum.reduce(required, [], fn {field, checker}, acc ->
          case value[field] do
            nil ->
              [{:settings, "#{field} can't be blank"} | acc]

            data ->
              if checker.(data) do
                acc
              else
                [{:settings, "#{field} is invalid"} | acc]
              end
          end
        end)
    end)
  end
end
