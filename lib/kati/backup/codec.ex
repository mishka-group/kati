defmodule Kati.Backup.Codec do
  @moduledoc """
  One column value, to JSON and back. Pure, and the only place that knows how a
  type is spelled in the file.

  Two rules run through all of it:

    * **Every date and instant is Gregorian ISO-8601 with ASCII digits.** The
      encoders take `Date`, `Time` and `DateTime` structs and print them with
      the standard library, so a `fa` locale — which draws `۱۴۰۴/۰۵/۳۰` on
      screen — cannot leak a Persian digit or a Jalali year into a file another
      program has to read. `Kati.BackupRoundTripTest` asserts the absence.
    * **Nothing here ever creates an atom from file input.** An attribute with
      a `one_of` constraint is decoded by matching against the constraint's own
      atoms, so a hostile or corrupt file cannot grow the atom table at all.
      The handful of unconstrained atom columns fall back to
      `String.to_existing_atom/1`, and then to `String.to_atom/1` only for a
      string that already looks like an Elixir atom literal.

  An unsupported type is a **loud failure at export time**. A column whose type
  this module has never seen is a column that would silently vanish from every
  backup taken after it landed, which is exactly the failure a backup exists to
  prevent.
  """

  alias Kati.Backup.Error

  # `String.to_atom/1` is only ever reached for a string of this shape, and only
  # for a column whose type is a constraint-free atom.
  @atom_literal ~r/\A[a-z][a-z0-9_]{0,63}\z/

  @doc """
  Encode one attribute's value for the payload.

  Raises `Kati.Backup.Error` on a type this module does not know — see the
  moduledoc for why that is a raise and not a `nil`.
  """
  @spec encode(Ash.Resource.Attribute.t(), term()) :: term()
  def encode(attribute, value), do: encode_value(attribute.type, value, attribute.name)

  @doc "Encode a value of a given Ash type. Exposed so the type table is testable."
  @spec encode_value(module(), term(), atom()) :: term()
  def encode_value(type, value, name \\ :unknown)

  def encode_value(_type, nil, _name), do: nil
  def encode_value(Ash.Type.UUID, value, _name) when is_binary(value), do: value
  def encode_value(Ash.Type.String, value, _name) when is_binary(value), do: value
  def encode_value(Ash.Type.Integer, value, _name) when is_integer(value), do: value
  def encode_value(Ash.Type.Float, value, _name) when is_number(value), do: value / 1
  def encode_value(Ash.Type.Boolean, value, _name) when is_boolean(value), do: value
  def encode_value(Ash.Type.Atom, value, _name) when is_atom(value), do: Atom.to_string(value)
  def encode_value(Ash.Type.Date, %Date{} = value, _name), do: Date.to_iso8601(value)
  def encode_value(Ash.Type.Time, %Time{} = value, _name), do: Time.to_iso8601(value)

  def encode_value(Ash.Type.UtcDatetimeUsec, %DateTime{} = value, _name),
    do: DateTime.to_iso8601(value)

  def encode_value(Ash.Type.UtcDatetime, %DateTime{} = value, _name),
    do: DateTime.to_iso8601(value)

  # A string, never a JSON number: a float is not a place to keep money, and a
  # decimal that goes out through a float comes back rounded.
  def encode_value(Ash.Type.Decimal, %Decimal{} = value, _name),
    do: Decimal.to_string(value, :normal)

  # A list, encoded element by element through the rules above. Recursing rather
  # than special-casing `{:array, :atom}` is what keeps a future array of dates
  # or integers from being a second bug: the element type decides, exactly as it
  # does for a scalar column, and an element type with no encoding still raises
  # rather than reaching JSON as something the decoder cannot read back.
  def encode_value({:array, element_type}, value, name) when is_list(value) do
    Enum.map(value, &encode_value(element_type, &1, name))
  end

  def encode_value(type, value, name) do
    raise Error.new(
            :unsupported_type,
            "Kati cannot write #{name} to a backup: no encoding is defined for #{inspect(type)}.",
            %{column: name, type: type, value: inspect(value)}
          )
  end

  @doc """
  Decode one attribute's value from the payload.

  Returns `{:error, sentence}` rather than raising: a bad value is one line in
  a list of everything else wrong with the file, gathered before anything is
  written.
  """
  @spec decode(Ash.Resource.Attribute.t(), term()) :: {:ok, term()} | {:error, String.t()}
  def decode(attribute, nil) do
    if attribute.allow_nil? do
      {:ok, nil}
    else
      {:error, "#{attribute.name} is null, and #{attribute.name} may not be null"}
    end
  end

  def decode(attribute, value) do
    decode_value(attribute.type, attribute.constraints, value, attribute.name)
  end

  @doc "Decode a value of a given Ash type. Exposed so the type table is testable."
  @spec decode_value(module(), keyword(), term(), atom()) :: {:ok, term()} | {:error, String.t()}
  def decode_value(type, constraints, value, name \\ :unknown)

  def decode_value(_type, _constraints, nil, _name), do: {:ok, nil}

  def decode_value(Ash.Type.UUID, _c, value, name) when is_binary(value) do
    if String.match?(value, ~r/\A[0-9a-fA-F-]{32,36}\z/) do
      {:ok, String.downcase(value)}
    else
      {:error, "#{name} is not a UUID: #{inspect(value)}"}
    end
  end

  def decode_value(Ash.Type.String, _c, value, _name) when is_binary(value), do: {:ok, value}
  def decode_value(Ash.Type.Integer, _c, value, _name) when is_integer(value), do: {:ok, value}
  def decode_value(Ash.Type.Boolean, _c, value, _name) when is_boolean(value), do: {:ok, value}

  def decode_value(Ash.Type.Float, _c, value, _name) when is_number(value),
    do: {:ok, value / 1}

  def decode_value(Ash.Type.Date, _c, value, name) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      {:error, _} -> {:error, "#{name} is not an ISO-8601 date: #{inspect(value)}"}
    end
  end

  def decode_value(Ash.Type.Time, _c, value, name) when is_binary(value) do
    case Time.from_iso8601(value) do
      {:ok, time} -> {:ok, time}
      {:error, _} -> {:error, "#{name} is not an ISO-8601 time: #{inspect(value)}"}
    end
  end

  def decode_value(type, _c, value, name)
      when type in [Ash.Type.UtcDatetimeUsec, Ash.Type.UtcDatetime] and is_binary(value) do
    # `DateTime.from_iso8601/1` returns the instant already in UTC and hands
    # back the offset it was written with, so an export from a phone in Tehran
    # and one from a phone in Amsterdam decode to the same instant.
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      {:error, _} -> {:error, "#{name} is not an ISO-8601 instant: #{inspect(value)}"}
    end
  end

  def decode_value(Ash.Type.Decimal, _c, value, name) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> {:ok, decimal}
      _ -> {:error, "#{name} is not a decimal: #{inspect(value)}"}
    end
  end

  def decode_value(Ash.Type.Atom, constraints, value, name) when is_binary(value) do
    case Keyword.get(constraints, :one_of) do
      nil -> loose_atom(value, name)
      allowed -> one_of(allowed, value, name)
    end
  end

  # The mirror of the array encoder. `items:` is where Ash puts an array's
  # element constraints, so a `one_of` on the elements is still enforced on the
  # way back in — a backup carrying a mood this version has never heard of is
  # refused with the column named, not silently turned into a new atom.
  def decode_value({:array, element_type}, constraints, value, name) when is_list(value) do
    item_constraints = Keyword.get(constraints, :items, [])

    value
    |> Enum.reduce_while({:ok, []}, fn element, {:ok, acc} ->
      case decode_value(element_type, item_constraints, element, name) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, decoded} -> {:ok, Enum.reverse(decoded)}
      {:error, reason} -> {:error, reason}
    end
  end

  def decode_value(type, _c, value, name) do
    {:error, "#{name} holds #{inspect(value)}, which is not a #{inspect(type)}"}
  end

  defp one_of(allowed, value, name) do
    case Enum.find(allowed, &(Atom.to_string(&1) == value)) do
      nil ->
        {:error,
         "#{name} is #{inspect(value)}, which is not one of " <>
           Enum.map_join(allowed, ", ", &inspect/1)}

      atom ->
        {:ok, atom}
    end
  end

  defp loose_atom(value, name) do
    {:ok, String.to_existing_atom(value)}
  rescue
    ArgumentError ->
      if String.match?(value, @atom_literal) do
        {:ok, String.to_atom(value)}
      else
        {:error, "#{name} is #{inspect(value)}, which is not a name Kati can use"}
      end
  end
end
