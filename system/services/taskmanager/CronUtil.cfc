/**
 * Service providing cron parsing and other cron related utility functions
 *
 * @singleton      true
 * @presideService true
 */
component displayName="Cron util" {

// CONSTRUCTOR
	public any function init() {
		_registerOsgiBundles();
		_setupCronParser();
		_setupTimezoneOffset();

		return this;
	}

// PUBLIC API METHODS
	public string function validateExpression( required string crontabExpression ) {
		try {
			_getCrontabExpressionObject( arguments.cronTabExpression );
		} catch ( any e ) {
			return e.message;
		}

		return "";
	}

	public string function getNextRunDate( required string crontabExpression, date lastRun=Now() ) {
		var cronTabExpression = _getCrontabExpressionObject( arguments.crontabExpression );
		var executionTimeObj  = _cronUtilsObj( "com.cronutils.model.time.ExecutionTime" ).forCron( cronTabExpression );

		return executionTimeObj.nextExecution( _createJavaZonedTimeObject( arguments.lastRun ) ).get().format( variables._dateTimeFormat );
	}

	public string function describeCronTabExression( required string crontabExpression, required string locale ) {
		if ( arguments.crontabExpression == "disabled" ) {
			return "disabled";
		}

		var locale     = CreateObject( "java", "java.util.Locale" ).forLanguageTag( UCase( ListFirst( arguments.locale, "-" ) ) );
		var cronObj    = _getCrontabExpressionObject( arguments.crontabExpression );
		var descriptor = _cronUtilsObj( "com.cronutils.descriptor.CronDescriptor" ).instance( locale );

		return descriptor.describe( cronObj );
	}


// PRIVATE HELPERS
	private any function _createJavaZonedTimeObject( required date cfmlDateTime ) {
		var formatted = DateFormat( arguments.cfmlDateTime, "yyyy-mm-dd" ) & "T"
		              & TimeFormat( arguments.cfmlDateTime, "HH:mm:ss" ) & variables._timezoneOffset;

		return CreateObject( "java", "java.time.ZonedDateTime" ).parse( formatted );
	}

	private any function _getCrontabExpressionObject( required string expression ) {
		return variables._cronParser.parse( _convertToValidQuartzCron( arguments.expression ) );
	}

	private string function _convertToValidQuartzCron( expression ) {
		var expressions = ListToArray( arguments.expression, " " );

		// quartz does not allow both day of month and day of week
		// replace one if both used with ?
		if ( ArrayLen( expressions ) >= 6 ) {
			if ( expressions[ 4 ] == "*" && expressions[ 6 ] != "?" ) {
				expressions[ 4 ] = "?";
			} else if ( expressions[ 4 ] != "?" ) {
				expressions[ 6 ] = "?"
			}
		}

		return ArrayToList( expressions, " " );
	}

	private void function _registerOsgiBundles() {
		var jars       = DirectoryList( "/preside/system/services/taskmanager/lib/", false, "path", "*.jar" );
		var cfmlEngine = CreateObject( "java", "lucee.loader.engine.CFMLEngineFactory" ).getInstance();
		var osgiUtil   = CreateObject( "java", "lucee.runtime.osgi.OSGiUtil" );

		for( var jar in jars ) {
			var res       = cfmlEngine.getResourceUtil().toResourceExisting( getPageContext(), jar );

			osgiUtil.installBundle( cfmlEngine.getBundleContext(), res, true );
		}
	}

	private void function _setupCronParser() {
		var cronTypes  = _cronUtilsObj( "com.cronutils.model.CronType" );
		var defBuilder = _cronUtilsObj( "com.cronutils.model.definition.CronDefinitionBuilder" );
		var def        = defBuilder.instanceDefinitionFor( cronTypes.QUARTZ );

		variables._cronParser = _cronUtilsObj( "com.cronutils.parser.CronParser" ).init( def );
	}

	private void function _setupTimezoneOffset() {
		var tzInfo = GetTimeZoneInfo();
		var hours  = NumberFormat( tzInfo.utcHourOffset, "00" );
		var mins   = NumberFormat( tzInfo.utcMinuteOffset, "00" );

		variables._timezoneOffset = "#hours#:#mins#";
		if ( Left( variables._timezoneOffset, "1" ) != "-" ) {
			variables._timezoneOffset = "+" & variables._timezoneOffset;
		}
		variables._dateTimeFormat = CreateObject( "java", "java.time.format.DateTimeFormatter" ).ISO_LOCAL_DATE_TIME;
	}

	private function _cronUtilsObj( className ) {
		return CreateObject( "java", arguments.className, "com.cronutils.cron-utils", "9.2.1" );
	}

}