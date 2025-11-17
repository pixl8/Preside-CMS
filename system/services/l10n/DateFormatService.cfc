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
    public string function getLongFormatMask() {
        if( _getLongFormat() == "DMY" ) {
            return "d mmmm yyyy";
        }
        else {
            return "mmmm d yyyy";
        }
    }

    public string function getLongFormatDayMask() {
        return "d";
    }

    public string function getLongFormatMonthMask() {
        return "mmmm";
    }

    public string function getLongFormatYearMask() {
        return "yyyy";
    }

    public string function getLongFormatDayMonthMask() {
        if( _getLongFormat() == "DMY" ) {
            return "d mmmm";
        }
        else {
            return "mmmm d";
        }
    }

    public string function getLongDate( required date date ) {
        return LSdateFormat( arguments.date, getLongFormatMask() );
    }

//DATE RANGE FUNCTIONS
    public string function getDateRangeWithSameMonth( required date date1, required date date2, showYear=false ) {
        var longFormat         = _getLongFormat();
        var mask               = getLongFormatMask();
		var maskNoYear         = getLongFormatDayMonthMask();
		var dayMask            = getLongFormatDayMask();
		var yearMask           = getLongFormatYearMask();

		if( longFormat == "DMY" ) {
            var dateRange = LSDateFormat( arguments.date1, dayMask );
            if( arguments.showYear ) {
                dateRange &= " - " & LSDateFormat( arguments.date2, mask );
            }
            else {
                dateRange &= " - " & LSDateFormat( arguments.date2, maskNoYear );
            }
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

    public string function getDateRangeWithDifferentMonthAndSameYear( required date date1, required date date2, showYear=false ) {
        var longFormat         = _getLongFormat();
        var mask               = getLongFormatMask();
		var maskNoYear         = getLongFormatDayMonthMask();
		var dayMonthMask       = getLongFormatDayMonthMask();

        if( !arguments.showYear ) {
            mask = maskNoYear;
        }

        if( longFormat == "DMY" ) {
			return "#LSDateFormat( date1, dayMonthMask )# - #LSDateFormat( date2, mask )#";
		}
		else {
			return "#LSDateFormat( date1, maskNoYear )# - #LSDateFormat( date2, mask )#";
		}
    }

    public string function getDateRangeWithDifferentMonthAndDifferentYear( required date date1, required date date2, showYear=false ) {
        var mask        = getLongFormatMask();
        var maskNoYear  = getLongFormatDayMonthMask();

        if( !arguments.showYear ) {
            mask = maskNoYear;
        }

        return "#LSDateFormat( date1, mask )# - #LSDateFormat( date2, mask )#";
    }

    public string function getSplitDate( required array dates, boolean compact=false, numeric compactThreshold=30 ) {
        var dayMask   = getLongFormatDayMask();
        var dmyOrder  = _getLongFormat();
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
				monthDates[monthNumber].append(LSDateFormat(date, dayMask));
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

    public function getSiteLocaleSettings() {
        var event                  = $getRequestContext();
        var currentSite            = event.getSite();
        var siteId                 = currentSite.id;

        return $getPresideObject( "site_localisation" ).selectData(
              filter = { site=siteId }
            , extraSelectFields = [ "site.locale" ]
        );
    }
    
//PRIVATE FUNCTIONS
    private struct function _getDefaultSettingsForLocale(){
        var localeSettings  = getSiteLocaleSettings();
        var defaultSettings = $getColdbox().getSetting( "datetime.localeDefaults" );

        if(Len(localeSettings.locale) && Structkeyexists(defaultSettings, localeSettings.locale)){
            return defaultSettings[localeSettings.locale];
        }
        else {
            return defaultSettings["en"];
        }
    }

    private string function _getLongFormat() {
        var defaults = _getDefaultSettingsForLocale();

        if( Len(getSiteLocaleSettings().long_date_format)) {
            return getSiteLocaleSettings().long_date_format;
        }
        else {
            return defaults.long_date_format;
        }
    }
}