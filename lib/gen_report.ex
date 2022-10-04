defmodule GenReport do
  alias GenReport.Parser

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report ->
      report
      |> update_all_hours(line)
      |> update_hours_per_month(line)
      |> update_hours_per_year(line)
    end)
  end

  def build, do: {:error, "Insira o nome de um arquivo"}

  defp update_all_hours(%{"all_hours" => all_hours} = report, [
         name,
         hours,
         _,
         _,
         _
       ]) do
    all_hours =
      Map.update(all_hours, name, hours, fn hours_present ->
        hours + hours_present
      end)

    %{report | "all_hours" => all_hours}
  end

  defp update_hours_per_month(%{"hours_per_month" => hours_per_month} = report, [
         name,
         hours,
         _,
         month,
         _
       ]) do
    hours_per_month =
      Map.update(hours_per_month, name, %{month => hours}, fn hours_by_name ->
        Map.update(hours_by_name, month, hours, fn hours_present ->
          hours + hours_present
        end)
      end)

    %{report | "hours_per_month" => hours_per_month}
  end

  defp update_hours_per_year(%{"hours_per_year" => hours_per_year} = report, [
         name,
         hours,
         _,
         _,
         year
       ]) do
    hours_per_year =
      Map.update(hours_per_year, name, %{year => hours}, fn hours_by_name ->
        Map.update(hours_by_name, year, hours, fn hours_present ->
          hours + hours_present
        end)
      end)

    %{report | "hours_per_year" => hours_per_year}
  end

  defp report_acc do
    %{
      "all_hours" => %{},
      "hours_per_month" => %{},
      "hours_per_year" => %{}
    }
  end
end
