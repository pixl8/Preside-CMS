<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	maxLength    = Val( args.maxLength ?: 0 );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<textarea id="#inputId#" placeholder="#placeholder#" name="#inputName#" class="richeditor" tabindex="#getNextTabIndex()#"<cfif Len( Trim( args.toolbar ?: "" ) )> data-toolbar="#Trim( args.toolbar )#"</cfif>>#value#</textarea>
</cfoutput>