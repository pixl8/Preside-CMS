<!---@feature admin and formbuilder--->
<cfparam name="args.responses"  type="array"  default=[] />
<cfparam name="args.noResponse" type="string" default="#translateResource( "formbuilder:no.response.placeholder" )#" />

<cfscript>
	var lines = [];
	for ( var response in args.responses ) {
		var hasRendered = StructKeyExists( response, "rendered" );
		var line        = ( response.item.configuration.label ?: response.item.configuration.name );

		if ( hasRendered ) {
			line &= ": " ;

			if ( Len( Trim( response.rendered ) ) ) {
				line &= response.rendered;
			} else {
				line &= args.noResponse;
			}
		} else {
			line &= Chr( 10 ) & "--------------";
		}

		ArrayAppend( lines, Trim( line ) );
	}
</cfscript>

<cfoutput>#ArrayToList( lines, Chr( 10 ) )#</cfoutput>
