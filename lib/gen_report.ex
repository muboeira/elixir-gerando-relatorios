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

  def build_from_many(filenames) do
    filenames
    |> Task.async_stream(&build/1)
    |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)
  end

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

  def sum_reports(
        %{
          "all_hours" => all_hours1,
          "hours_per_year" => hours_per_year1,
          "hours_per_month" => hours_per_month1
        },
        %{
          "all_hours" => all_hours2,
          "hours_per_year" => hours_per_year2,
          "hours_per_month" => hours_per_month2
        }
      ) do
    all_hours = merge_maps(all_hours1, all_hours2)
    hours_per_month = merge_maps(hours_per_month1, hours_per_month2)
    hours_per_year = merge_maps(hours_per_year1, hours_per_year2)

    %{
      "all_hours" => all_hours,
      "hours_per_year" => hours_per_year,
      "hours_per_month" => hours_per_month
    }
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> calc_merge_maps(value1, value2) end)
  end

  defp calc_merge_maps(value1, value2) when is_map(value1) and is_map(value2) do
    merge_maps(value1, value2)
  end

  defp calc_merge_maps(value1, value2) when is_integer(value1) and is_integer(value2) do
    value1 + value2
  end

  defp report_acc do
    %{
      "all_hours" => %{},
      "hours_per_month" => %{},
      "hours_per_year" => %{}
    }
  end
end
