/**
 * @singleton true
 * @presideService true
 */
component {

    function init() {
		return this;
	}

    public string function getTimeFormatMask(  ){
        var localeSettings = $helpers.getSiteLocaleSettings();
        
        if(localeSettings.time_format == "12h") {
            return "h:mmtt";
        }
        else {
            return "HH:mm";
        }
    }

    public string function roundHours( string formattedTime ){
        var localeSettings = $helpers.getSiteLocaleSettings();
        
        if(localeSettings.time_format == "12h") {
            return Replace(arguments.formattedTime, ":00", "", "all");
        }

        return arguments.formattedTime;
    }

    public string function getFormattedTime( required date date ){
        return LSTimeFormat(arguments.date, getTimeFormatMask());
    }

}