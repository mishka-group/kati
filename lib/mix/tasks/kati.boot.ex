defmodule Mix.Tasks.Kati.Boot do
  @shortdoc "Measure cold start on every connected Android device"

  @moduledoc """
  How long Kati takes from launcher tap to a rendered first screen, per phase.

      mix kati.boot              # five runs, median reported
      mix kati.boot --runs 3
      mix kati.boot --device <serial>

  ## Why this is a Mix task and not a page of adb

  #37 asks for a measurement on a real mid-range phone, and the measurement is
  five force-stops, five timed launches and a logcat filter each time. Written
  out as shell it is a paragraph nobody runs twice, and the numbers it produces
  land in a terminal scrollback rather than anywhere they can be compared with
  last week's.

  Every other thing this project does to a device is a Mix task — `mob.deploy`,
  `mob.devices`, `mob.connect` — and this reuses their device discovery, so it
  finds the same phone they do without being told which.

  ## What it reports

  Three layers, which is what makes the number actionable rather than merely
  alarming:

    * **`am start -W`** — `TotalTime` and `WaitTime`, the OS's own view.
    * **mob's phase markers** — including the window-focus wait, which is a
      timeout of 3000ms rather than a cost and had been read as a cost.
    * **`Kati.App.trace/1`** — the per-statement split inside `on_start/0`,
      which is the half that says *which line to move*.

  Runs are reported as a median because a single cold start on a phone is
  mostly noise, and the median of five is the number #37 asks for.

  ## What it cannot tell you

  A dev deploy pushes unstripped `_build/dev` beams — the full CLDR set among
  them — so these numbers are an upper bound rather than the shipped figure.
  The first launch after an install additionally extracts `otp.zip`, which this
  does not isolate; force-stopping restarts the process, not the install.
  """

  use Mix.Task

  @default_runs 5

  @impl Mix.Task
  def run(argv) do
    {opts, _rest} = OptionParser.parse!(argv, strict: [runs: :integer, device: :string])
    runs = Keyword.get(opts, :runs, @default_runs)

    package = package!()
    devices = devices!(Keyword.get(opts, :device))

    for device <- devices do
      Mix.shell().info("\n#{device} — #{package}, #{runs} runs")
      measure(device, package, runs)
    end
  end

  # `MobDev.Config.bundle_id/0` is the same reader `mix mob.deploy` uses, so
  # this cannot measure a different app than the one that was deployed.
  defp package!, do: MobDev.Config.bundle_id()

  defp devices!(nil) do
    case MobDev.Discovery.Android.list_devices() do
      [] -> Mix.raise("no Android device connected. `mix mob.devices` to diagnose.")
      found -> Enum.map(found, & &1.serial)
    end
  end

  defp devices!(serial), do: [serial]

  defp measure(serial, package, runs) do
    samples = for n <- 1..runs, do: one_run(serial, package, n, runs)

    Mix.shell().info("")
    report(samples)
  end

  # One cold start: kill it, clear the log, launch it timed, wait for the boot
  # to finish, read the markers back. The force-stop is what makes it cold —
  # without it the second run measures a warm process and reports a number
  # that is real and answers a different question.
  defp one_run(serial, package, n, runs) do
    adb(serial, ["shell", "am", "force-stop", package])
    Process.sleep(2_000)
    adb(serial, ["logcat", "-c"])

    started = adb(serial, ["shell", "am", "start", "-W", "-n", package <> "/.MainActivity"])
    Process.sleep(20_000)

    log = adb(serial, ["logcat", "-d"])
    Mix.shell().info("  run #{n}/#{runs}")

    %{
      total: field(started, "TotalTime"),
      wait: field(started, "WaitTime"),
      focus: focus_wait(log),
      phases: phases(log)
    }
  end

  defp adb(serial, args) do
    case System.cmd("adb", ["-s", serial] ++ args, stderr_to_stdout: true) do
      {out, 0} -> out
      {out, code} -> Mix.raise("adb #{Enum.join(args, " ")} exited #{code}:\n#{out}")
    end
  end

  defp field(output, key) do
    case Regex.run(~r/#{key}:\s*(\d+)/, output) do
      [_, value] -> String.to_integer(value)
      nil -> nil
    end
  end

  defp focus_wait(log) do
    case Regex.run(~r/waited (\d+) ms for window focus/, log) do
      [_, value] -> String.to_integer(value)
      nil -> nil
    end
  end

  # `Kati.boot: <phase> +<delta>ms (<total>ms)` — written by Kati.App.trace/1.
  defp phases(log) do
    ~r/Kati\.boot: (\S+) \+(\d+)ms \((\d+)ms\)/
    |> Regex.scan(log)
    |> Enum.map(fn [_, phase, delta, total] ->
      {phase, String.to_integer(delta), String.to_integer(total)}
    end)
  end

  defp report(samples) do
    row("am start TotalTime", Enum.map(samples, & &1.total))
    row("am start WaitTime", Enum.map(samples, & &1.wait))
    row("window focus wait", Enum.map(samples, & &1.focus))

    Mix.shell().info("")

    samples
    |> Enum.flat_map(& &1.phases)
    |> Enum.group_by(fn {phase, _d, _t} -> phase end, fn {_p, delta, _t} -> delta end)
    |> Enum.sort_by(fn {phase, _} -> order(samples, phase) end)
    |> Enum.each(fn {phase, deltas} -> row("  " <> phase, deltas) end)

    totals =
      for %{phases: phases} <- samples,
          {_p, _d, total} <- Enum.take(phases, -1),
          do: total

    Mix.shell().info("")
    row("on_start/0 total", totals)
  end

  # Phases print in the order they happened rather than alphabetically: the
  # sequence is the finding, and a sorted list hides where the time falls.
  defp order(samples, phase) do
    samples
    |> Enum.flat_map(& &1.phases)
    |> Enum.find_index(fn {name, _d, _t} -> name == phase end)
    |> Kernel.||(0)
  end

  defp row(label, values) do
    values = Enum.reject(values, &is_nil/1)

    if values == [] do
      Mix.shell().info(String.pad_trailing(label, 22) <> "—")
    else
      Mix.shell().info(
        String.pad_trailing(label, 22) <>
          "#{median(values)} ms   (#{Enum.min(values)}–#{Enum.max(values)})"
      )
    end
  end

  defp median(values) do
    sorted = Enum.sort(values)
    Enum.at(sorted, div(length(sorted), 2))
  end
end
