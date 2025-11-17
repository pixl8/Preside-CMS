/**
 * @singleton true
 * @presideService true
 */
component {

    property name="dateFormatService" inject="DateFormatService";

    function init() {
		return this;
	}

    public string function getTimeFormatMask(  ){
        var localeSettings = dateFormatService.getSiteLocaleSettings();
        
        if(localeSettings.time_format == "12h") {
            return "h:mmtt";
        }
        else {
            return "HH:mm";
        }
    }

    public string function roundHours( string formattedTime ){
        var localeSettings = dateFormatService.getSiteLocaleSettings();
        
        if(localeSettings.time_format == "12h") {
            return Replace(arguments.formattedTime, ":00", "", "all");
        }

        return arguments.formattedTime;
    }

    public string function getFormattedTime( required date date ){
        return LSTimeFormat(arguments.date, getTimeFormatMask());
    }

}