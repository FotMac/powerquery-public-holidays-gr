// Dynamic holiday calendar based on current date
// Automatically generates multiple years in the past and future
// Uses native Power BI (Power Query) functionality

let
    CurrentYear = Date.Year(DateTime.LocalNow()),
    StartYear = CurrentYear - 15,
    EndYear = CurrentYear + 10,
    Years = List.Numbers(StartYear, EndYear - StartYear + 1),
    GetHolidays = (year as number) as table =>
        let
            url = "https://date.nager.at/api/v3/PublicHolidays/" & Text.From(year) & "/GR",
            source = try Json.Document(Web.Contents(url)) otherwise null,
            table = if source <> null and List.Count(source) > 0 then
                Table.AddColumn(
                    Table.AddColumn(
                        Table.ExpandRecordColumn(
                            Table.FromList(source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
                            "Column1", {"date", "localName", "name", "types"}, {"Date", "LocalName", "Name", "Types"}
                        ),
                        "Year", each year
                    ),
                    "DayOfWeek", each Date.DayOfWeekName(Date.FromText([Date]))
                )
            else
                null
        in
            table,
    AllHolidays = List.Transform(Years, each GetHolidays(_)),
    Combined = Table.Combine(List.RemoveNulls(AllHolidays)),
    #"Reordered Columns" = Table.ReorderColumns(Combined,{"Date", "DayOfWeek", "LocalName", "Name", "Types", "Year"}),
    #"Removed Columns" = Table.RemoveColumns(#"Reordered Columns",{"Types", "Name"})
in
    #"Removed Columns"
