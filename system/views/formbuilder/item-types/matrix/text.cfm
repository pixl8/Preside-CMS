<!---@feature formbuilder--->
<cfparam name="args.answers" type="array" default=[] />

<cfscript>
	var config = args.itemConfiguration ?: ( args.configuration ?: {} );
	var offset = Len( ( config.label ?: "" ) & ": " );
	var lines = [];

	for ( var i=1; i<=ArrayLen( args.answers ); i++ ) {
		var line = "#args.answers[ i ].question# : #args.answers[ i ].answer#";

		if ( i > 1  ) {
			line = RepeatString( " ", offset ) & line;
		}

		ArrayAppend( lines, line );
	}
</cfscript>

<cfoutput>#ArrayToList( lines, Chr( 10 ) )#</cfoutput>