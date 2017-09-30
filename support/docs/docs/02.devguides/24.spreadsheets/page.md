---
id: spreadsheets
title: Working with spreadsheets
---

As of v10.5.0, PresideCMS comes with a built in spreadsheet library. Lucee itself does not have any out-of-box `<cfspreadsheet` functionality so traditionally an extension will be installed to provide compatibility. However, to avoid dependencies on server extension installs, we decided to include a library that would be available as part of the software.

The library we have used is [lucee-spreadsheet](https://github.com/cfsimplicity/lucee-spreadsheet) by [Julian Halliwell](https://github.com/cfsimplicity) (cfsimplicity).

Full documentation can be found at the links above, however, a quick start example follows:

```luceescript
// sometesthandler.cfc
component {

    // PresideCMS makes the library available as 'spreadsheetLib'
    // that can be injected with wirebox
    property name="spreadsheetLib" inject="spreadsheetLib";

    function index() {
        var workbook    = spreadSheetLib.new();
        var data        = QueryNew( "First,Last", "VarChar,VarChar", [
              [ "Susi"  , "Sorglos"  ]
            , [ "Frumpo", "McNugget" ]
        ] );

        spreadSheetLib.addRows( workbook, data );
        spreadSheetLib.download( workbook, "testfile.xls" );
    }

}
```
