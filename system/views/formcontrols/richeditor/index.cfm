<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	extraClasses = args.extraClasses ?: "";
	maxLength    = Val( args.maxLength ?: 0 );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<textarea id          = "#inputId#"
	          placeholder = "#placeholder#"
	          name        = "#inputName#"
	          class       = "richeditor #extraClasses#"
	          tabindex="#getNextTabIndex()#"
	          <cfif Len( Trim( args.toolbar ?: "" ) )>
	               data-toolbar = "#Trim( args.toolbar )#"
	          </cfif>
	          <cfif Len( Trim( args.customConfig ?: "" ) )>
	              data-custom-config="#Trim( args.customConfig )#"
	          </cfif>
	          <cfif Val( args.width ?: "" )>
	              data-width="#Val( args.width )#"
	          </cfif>
	          <cfif Val( args.height ?: "" )>
	              data-height="#Val( args.height )#"
	          </cfif>
	>#value#</textarea>
</cfoutput>