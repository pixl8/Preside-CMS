<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	values       = args.values       ?: "";
	defaultValue = args.defaultValue ?: "";

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<cfloop array="#values#" index="i" item="selectValue">
		<cfset checked   = ListFindNoCase( value, selectValue ) />
		<label class="radio-inline">
		  	<input type="radio"
		  		   id="#inputId#"
		  		   name="#inputName#"
		  		   value="#HtmlEditFormat( selectValue )#"
		  		   class="#inputClass#"
		  		   tabindex="#getNextTabIndex()#"
		  		   <cfif checked>checked</cfif>>
		  		   #HtmlEditFormat( selectValue )#
		</label>
	</cfloop>
</cfoutput>