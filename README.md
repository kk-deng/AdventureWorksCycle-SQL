# AdventureWorksCycle-SQL

AdventureWorks Database is a Microsoft product sample for an online transaction processing (OLTP) database. The AdventureWorks Database supports a fictitious, multinational manufacturing company called Adventure Works Cycles. 


* Using `CALCULATE` and `ALL` functions to calculate the percentage of total by ignoring the filters.

```DAX
% Of TotalOrderAddress = CALCULATE(COUNT('Sales SalesOrderHeader'[BillToAddressID]))/CALCULATE(COUNT('Sales SalesOrderHeader'[BillToAddressID]),ALL('Sales SalesOrderHeader'))
```


* Create a calendar dimension table

* Power Query to create a date dimension table 

```
let
    StartDate = #date(StartYear,5,1),
    EndDate = #date(EndYear,6,30),
    NumberOfDays = Duration.Days( EndDate - StartDate ),
    Dates = List.Dates(StartDate, NumberOfDays+1, #duration(1,0,0,0)),
    #"Converted to Table" = Table.FromList(Dates, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "FullDateAlternateKey"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"FullDateAlternateKey", type date}}),
    #"Inserted Year" = Table.AddColumn(#"Changed Type", "Year", each Date.Year([FullDateAlternateKey]), type number),
    #"Inserted Month" = Table.AddColumn(#"Inserted Year", "Month", each Date.Month([FullDateAlternateKey]), type number),
    #"Inserted Month Name" = Table.AddColumn(#"Inserted Month", "Month Name", each Date.MonthName([FullDateAlternateKey]), type text),
    #"Inserted Quarter" = Table.AddColumn(#"Inserted Month Name", "Quarter", each Date.QuarterOfYear([FullDateAlternateKey]), type number),
    #"Inserted Week of Year" = Table.AddColumn(#"Inserted Quarter", "Week of Year", each Date.WeekOfYear([FullDateAlternateKey]), type number),
    #"Inserted Week of Month" = Table.AddColumn(#"Inserted Week of Year", "Week of Month", each Date.WeekOfMonth([FullDateAlternateKey]), type number),
    #"Inserted Day" = Table.AddColumn(#"Inserted Week of Month", "Day", each Date.Day([FullDateAlternateKey]), type number),
    #"Inserted Day of Week" = Table.AddColumn(#"Inserted Day", "Day of Week", each Date.DayOfWeek([FullDateAlternateKey]) + 1, type number),
    #"Inserted Day of Year" = Table.AddColumn(#"Inserted Day of Week", "Day of Year", each Date.DayOfYear([FullDateAlternateKey]), type number),
    #"Inserted Day Name" = Table.AddColumn(#"Inserted Day of Year", "Day Name", each Date.DayOfWeekName([FullDateAlternateKey]), type text),
    #"Inserted Start of Week" = Table.AddColumn(#"Inserted Day Name", "Start of Week", each Date.StartOfWeek([FullDateAlternateKey]), type date),
    #"Inserted Start of Month" = Table.AddColumn(#"Inserted Start of Week", "Start of Month", each Date.StartOfMonth([FullDateAlternateKey]), type date),
    #"Inserted Short Day" = Table.AddColumn(#"Inserted Start of Month", "Short Day", each Date.ToText([FullDateAlternateKey], "ddd")),
    #"Inserted Short Month" = Table.AddColumn(#"Inserted Short Day", "Short Month", each Date.ToText([FullDateAlternateKey], "MMM"))
in
    #"Inserted Short Month"
```
```
DimDate = ADDCOLUMNS(CALENDAR(MIN('Sales SalesOrderHeader'[OrderDate]), MAX('Sales SalesOrderHeader'[OrderDate]))
                        , "Short Month", FORMAT([Date], "MMM")
                        , "Short Day", FORMAT([Date], "ddd")
                        , "Year", YEAR([Date])
                        , "Month", MONTH([Date])
                        , "Quarter", QUARTER([Date])
                        , "Week of Year", WEEKNUM([Date])
                        , "Day", DAY([Date])
                        , "Day of Week", WEEKDAY([Date])
                        , "Day Name", FORMAT([Date], "dddd")
                    )
```