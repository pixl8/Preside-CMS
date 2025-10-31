/**
 * @singleton true
 * @presideService true
 */
component {

    function init() {
		return this;
	}

    public string function getDayMask() {
        return $translateResource( uri="dateformat:day.mask");
    }

    public string function getDateMask() {
        return $translateResource( uri="dateformat:date.mask");
    }

    public string function getMonthMask() {
        return $translateResource( uri="dateformat:month.mask");
    }

    public string function getDayMonthMask() {
        return $translateResource( uri="dateformat:daymonth.mask");
    }

    public string function getYearMask() {
        return $translateResource( uri="dateformat:year.mask");
    }

    public string function getDayMonthYearMask() {
        return $translateResource( uri="dateformat:daymonthyear.mask");
    }

    public string function getShortDateFormatMask() {
        return $translateResource( uri="dateformat:shortdate.mask");
    }

    public string function getShortDate( required date date ) {
        return LSdateFormat( arguments.date, getShortDateFormatMask() );
    }

    public string function getDateWithFullMonthMask() {
        return $translateResource( uri="dateformat:fullmonthdate.mask");
    }

    public string function getDateWithFullMonthName( required date date ) {
        return LSdateFormat( arguments.date, getDateWithFullMonthMask() );
    }

    public string function getDateRangeWithSameMonth( required date date1, required date date2, showYear=false ) {
        var mask               = arguments.showYear ? $translateResource( uri="dateformat:daterange.samemonth.withyear.mask") : $translateResource( uri="dateformat:daterange.samemonthnoyear.mask");
        var daterangeSeparator = $translateResource( uri="dateformat:daterange.separator");
        var maskParts          = ListToArray(mask, trim(daterangeSeparator));
        var part1              = LSDateFormat( arguments.date1, maskParts[1] );
        var part2              = LSDateFormat( arguments.date2, maskParts[2] );

        return part1 & daterangeSeparator & part2;
    }

    public string function getDateRangeWithDifferentMonthAndSameYear( required date date1, required date date2 ) {
        var mask               = $translateResource( uri="dateformat:daterange.differentmonthssameyear.mask");
        var daterangeSeparator = $translateResource( uri="dateformat:daterange.separator");
        var maskParts          = ListToArray(mask, trim(daterangeSeparator));
        var part1              = LSDateFormat( arguments.date1, maskParts[1] );
        var part2              = LSDateFormat( arguments.date2, maskParts[2] );

        return part1 & daterangeSeparator & part2;
    }

    public string function getDateRangeWithDifferentMonthAndDifferentYear( required date date1, required date date2 ) {
        var mask               = $translateResource( uri="dateformat:daterange.differentmonthsdifferentyear.mask");
        var daterangeSeparator = $translateResource( uri="dateformat:daterange.separator");
        var maskParts          = ListToArray(mask, trim(daterangeSeparator));
        var part1              = LSDateFormat( arguments.date1, maskParts[1] );
        var part2              = LSDateFormat( arguments.date2, maskParts[2] );

        return part1 & daterangeSeparator & part2;
    }

    public string function getDateRangeWithDifferentMonths( required date date1, required date date2 ) {
        return LSdateFormat( arguments.date1, getDateWithFullMonthMask() ) & " - " & LSdateFormat( arguments.date2, getDateWithFullMonthMask() );
    }

    
    
}