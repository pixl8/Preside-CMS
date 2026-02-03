<!---@feature admin--->
<cfscript>
	position = args.position ?: "bottom-right";
	alerts   = args.alerts   ?: [];
	title    = args.title    ?: "";
</cfscript>
<cfoutput>
	( function( $ ){
		$.gritter.options.position = "#position#";
		<cfloop array="#alerts#" index="alert">
		$.gritter.add( {
			  title      : #SerializeJson( title )#
			, text       : #SerializeJson( alert )#
			, class_name : "gritter-error"
			, sticky     : true
		} );
		</cfloop>
	} ) ( presideJQuery );
</cfoutput>