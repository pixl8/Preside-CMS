/**
 * @presideService true
 * @singleton      true
 * @feature        admin
 */
component {

// CONSTRUCTOR
	public any function init() {
		variables._logLevels = new coldbox.system.logging.LogLevels();
		return this;
	}

// PUBLIC API METHODS
	public string function renderLogs( required query lines, numeric startingLineNumber=0 ) {
		var outputArray = [];
		var lineNumber  = arguments.startingLineNumber;

		for( var line in lines ) {
			var logLevel = variables._logLevels.lookup( line.severity );
			var logClass = LCase( logLevel );
			var t        = DateAdd( 's', line.ts, '1970-01-01 00:00:00' );

			ArrayAppend( outputArray, "<span class=""line-number"">#++lineNumber#.</span> <span class=""task-log-line task-log-#logClass#"">[#logLevel#] <span class=""task-log-datetime"">[#DateTimeFormat( t, 'yyyy-mm-dd HH:nn:ss' )#]</span> #line.line#</span>" );
		}

		return ArrayToList( outputArray, Chr(10) );
	}

	public string function renderLegacyLogs( required string log, numeric fetchAfterLines=0 ) {
		var logArray = ListToArray( arguments.log, Chr(10) );
		var outputArray = [];

		for( var i=arguments.fetchAfterLines+1; i <= logArray.len(); i++ ){
			var line          = logArray[ i ];
			var logClass      = LCase( ReReplace( line, '^\[(.*?)\].*$', '\1' ) );
			var dateTimeRegex = "(\[20[0-9]{2}\-[0-9]{2}\-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\])";

			line = ReReplace( line, dateTimeRegex, '<span class="task-log-datetime">\1</span>' );
			line = '<span class="line-number">#i#.</span> <span class="task-log-line task-log-#logClass#">' & line & '</span>';

			outputArray.append( line );
		}

		return outputArray.toList( Chr(10) );
	}
}