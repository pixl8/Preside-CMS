/**
 * @singleton true
 * @presideService true
 */
component {

    function init() {
		return this;
	}

    

//SHORT DATE FORMAT FUNCTIONS
    public string function getShortDateFormatMask() {
        return LCase(getSiteLocaleSettings().short_date_format);
    }

    public string function getShortDate( required date date ) {
        return LSdateFormat( arguments.date, getShortDateFormatMask() );
    }

//LONG DATE FORMAT FUNCTIONS
    public string function getLongDateFormatMask() {
        if( _getLongDateFormat() == "DMY" ) {
            return "d mmmm yyyy";
        }
        else {
            return "mmmm d, yyyy";
        }
    }

    public string function getLongDateFormatDayMask() {
        return "d";
    }

    public string function getLongDateFormatMonthMask() {
        return "mmmm";
    }

    public string function getLongDateFormatYearMask() {
        return "yyyy";
    }

    public string function getLongDateFormatDayMonthMask() {
        if( _getLongDateFormat() == "DMY" ) {
            return "d mmmm";
        }
        else {
            return "mmmm d";
        }
    }

    public string function getLongDate( required date date, boolean includeOrdinal=false ) {
        var longFormat    = _getLongDateFormat();
        var mask          = getLongDateFormatMask();
        var formattedDate = LSdateFormat( arguments.date, mask );

        if( arguments.includeOrdinal && longFormat == "DMY" ) {
            var dateOrdinal = getDateDayOrdinal( arguments.date );
            formattedDate   = ReReplace( formattedDate, "(\d{1,2})", "\1#dateOrdinal#" ); 
        }

        return formattedDate;
    }

//DATE RANGE FUNCTIONS
    public string function getDateRange( required date date1, required date date2, boolean showYear=false, boolean includeOrdinal=false ) {
        var longFormat = _getLongDateFormat();
        var mask       = getLongDateFormatMask();
        var maskNoYear = getLongDateFormatDayMonthMask();
        var dayMask    = getLongDateFormatDayMask();
        var yearMask   = getLongDateFormatYearMask();

        if( arguments.includeOrdinal && longFormat == "MDY" ) {
            arguments.includeOrdinal = false;
        }

        if( month( arguments.date1 ) == month( arguments.date2 ) ) {
            return getDateRangeWithSameMonth( arguments.date1, arguments.date2, arguments.showYear, includeOrdinal );
        }
        else {
            if( year( arguments.date1 ) == year( arguments.date2 ) ) {
                return getDateRangeWithDifferentMonthAndSameYear( arguments.date1, arguments.date2, arguments.showYear, includeOrdinal );
            }
            else {
                return getDateRangeWithDifferentMonthAndDifferentYear( arguments.date1, arguments.date2, arguments.showYear, includeOrdinal );
            }
        }
        
    }

    public string function getDateRangeWithSameMonth( required date date1, required date date2, showYear=false, boolean includeOrdinal=false ) {
        var longFormat         = _getLongDateFormat();
        var mask               = getLongDateFormatMask();
		var maskNoYear         = getLongDateFormatDayMonthMask();
		var dayMask            = getLongDateFormatDayMask();
		var yearMask           = getLongDateFormatYearMask();

		if( longFormat == "DMY" ) {
            var dateRange = LSDateFormat( arguments.date1, dayMask );
            if( arguments.includeOrdinal ) {
                dateRange &= getDateDayOrdinal( arguments.date1 );
            }

            var date2Part = "";
            
            if( arguments.showYear ) {
                date2Part = LSDateFormat( arguments.date2, mask );
            }
            else {
                date2Part = LSDateFormat( arguments.date2, maskNoYear );
            }

            if( arguments.includeOrdinal ) {
                var date2Ordinal = getDateDayOrdinal( arguments.date2 );
                date2Part = ReReplace( date2Part, "(\d{1,2})", "\1#date2Ordinal#" );
            }

            dateRange &= " - " & date2Part;

            return dateRange;
		}
		else {
            var dateRange = "#LSDateFormat( arguments.date1, maskNoYear )# - #LSDateFormat( arguments.date2, dayMask )#";
            if( arguments.showYear ) {
                dateRange &= " " & LSDateFormat( arguments.date1, yearMask );
            }
            return dateRange;
		}
    }

    public string function getDateRangeWithDifferentMonthAndSameYear( required date date1, required date date2, showYear=false, boolean includeOrdinal=false ) {
        var longFormat         = _getLongDateFormat();
        var mask               = getLongDateFormatMask();
		var maskNoYear         = getLongDateFormatDayMonthMask();
		var dayMonthMask       = getLongDateFormatDayMonthMask();

        if( !arguments.showYear ) {
            mask = maskNoYear;
        }

        if( longFormat == "DMY" ) {
            var date1Part = LSDateFormat( date1, dayMonthMask );
            var date2Part = LSDateFormat( date2, mask );

            if( arguments.includeOrdinal ) {
                var date1Ordinal = getDateDayOrdinal( arguments.date1 );
                date1Part = ReReplace( date1Part, "(\d{1,2})", "\1#date1Ordinal#" );

                var date2Ordinal = getDateDayOrdinal( arguments.date2 );
                date2Part = ReReplace( date2Part, "(\d{1,2})", "\1#date2Ordinal#" );
            }
            
			return "#date1Part# - #date2Part#";
		}
		else {
			return "#LSDateFormat( date1, maskNoYear )# - #LSDateFormat( date2, mask )#";
		}
    }

    public string function getDateRangeWithDifferentMonthAndDifferentYear( required date date1, required date date2, showYear=false, boolean includeOrdinal=false ) {
        var mask        = getLongDateFormatMask();
        var maskNoYear  = getLongDateFormatDayMonthMask();

        if( !arguments.showYear ) {
            mask = maskNoYear;
        }

        var date1Part = LSDateFormat( date1, mask );
        var date2Part = LSDateFormat( date2, mask );

        if( arguments.includeOrdinal ) {
            var date1Ordinal = getDateDayOrdinal( arguments.date1 );
            date1Part = ReReplace( date1Part, "(\d{1,2})", "\1#date1Ordinal#" );

            var date2Ordinal = getDateDayOrdinal( arguments.date2 );
            date2Part = ReReplace( date2Part, "(\d{1,2})", "\1#date2Ordinal#" );
        }

        return "#date1Part# - #date2Part#";
    }

    public string function getSplitDate( required array dates, boolean compact=false, numeric compactThreshold=30, boolean includeOrdinal=false ) {
        var dayMask   = getLongDateFormatDayMask();
        var dmyOrder  = _getLongDateFormat();
        var delimiter = ", ";
        
        //sort the dates by year
		ArraySort(arguments.dates, function(a,b) {
			return DateCompare(a,b, "y");
		});
		
        //get the unique years from the dates
        var years = [];
		for( var date in arguments.dates ) {
			if( !ArrayContains(years, year(date)) ) {
				ArrayAppend(years, year(date));
			}
		}
        
		var formattedDates = [];
        //loop through the years
		for(var year in years) {
			var formattedYearDates = "";
			var monthDates   = {};
			var monthNumbers = [];

            //get the dates for the current year
			var yearDates = ArrayFilter(arguments.dates, function(date) {
				return year(date) == year;
			});

			//loop through the dates for the current year
			for( var date in yearDates ) {
				var monthNumber = month(date);
				if( !ArrayContains(monthNumbers, monthNumber) ) {
					ArrayAppend(monthNumbers, monthNumber);
				}

				if( !StructKeyExists(monthDates, monthNumber) ) {
					monthDates[monthNumber] = [];
				}

                var monthDate = LSDateFormat(date, dayMask);

                if( arguments.includeOrdinal && dmyOrder == "DMY" ) {
                    var dayOrdinal  = getDateDayOrdinal( date );
                    monthDate &= dayOrdinal;
                }

				monthDates[monthNumber].append(monthDate);
			}

			//sort the month numbers numerically ascending
			ArraySort(monthNumbers, "numeric", "asc");

			//loop through the month numbers
			for( var i=1; i<=ArrayLen(monthNumbers); i++ ) {
				//get the month number
				var monthNumber = monthNumbers[i];
                

				if( dmyOrder == "DMY" ) {
					formattedYearDates &= ArrayToList(monthDates[monthNumber], delimiter) & " " & MonthAsString(monthNumber) & delimiter;
				}
				else if( dmyOrder == "MDY" || dmyOrder == "YMD" ) {
					formattedYearDates &= MonthAsString(monthNumber) & " " & ArrayToList(monthDates[monthNumber], delimiter) & delimiter;
				}
			}

            //strip the trailing delimiter
			if( Right(formattedYearDates, 2) == delimiter ) {
				formattedYearDates = Left(formattedYearDates, Len(formattedYearDates) - Len(delimiter));
			}

            //add the year depending on the day month year order
			if( dmyOrder == "DMY" || dmyOrder == "MDY" ) {
				formattedYearDates &= " " & year;
			}
			else if( dmyOrder == "YMD" ) {
				formattedYearDates = year & " " & formattedYearDates;
			}

			ArrayAppend(formattedDates, formattedYearDates);
		}

        return ArrayToList(formattedDates, delimiter);
    }

    public query function getSiteLocaleSettings() {
        var event                  = $getRequestContext();
        var currentSite            = event.getSite();
        var siteId                 = currentSite.id;

        return $getPresideObject( "site" ).selectData(
              filter = { id=siteId }
        );
    }

    public struct function getDefaultSettingsForLocale(){
        var localeSettings  = getSiteLocaleSettings();
        var defaultSettings = $getColdbox().getSetting( "datetime.regionDefaults" );
        var countryCode     = ListLast(localeSettings.locale, "_");
        var regionCode      = $translateResource( uri="enum.isoCountries:#countryCode#.region");
        
        if(Len(countryCode) && Len(regionCode) && Structkeyexists(defaultSettings, regionCode)){
            return defaultSettings[regionCode];
        }
        else {
            return defaultSettings["uk"];
        }
    }

    public string function getDateDayOrdinal( required date date ){
        var ordinalTypeA = [ "st", "nd", "rd" ];
        var ordinal      = "th"
        var date         = DateFormat( arguments.date, "dd" );

        if( ( val( date[1] ) != 1 ) && ( date[2] > 0 && date[2] <= arrayLen( ordinalTypeA) ) ) {
            ordinal = ordinalTypeA[date[2]];
        }

        return ordinal
    }
    
//PRIVATE FUNCTIONS
    private string function _getLongDateFormat() {
        var defaults = getDefaultSettingsForLocale();

        if( Len(getSiteLocaleSettings().long_date_format)) {
            return getSiteLocaleSettings().long_date_format;
        }
        else {
            return defaults.long_date_format;
        }
    }

    
}