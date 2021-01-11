<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "form-control";
	extraClasses = args.extraClasses ?: "";
	sortable     = args.sortable     ?: false;
	selectSize   = args.selectSize   ?: "";
	defaultValue = args.defaultValue ?: "";
	values       = args.values       ?: "";
	labels       = ( structKeyExists( args, "labels") && len( args.labels ) ) ? args.labels : args.values;

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<p><small>#translateResource( "formcontrols.multiSelectPanel:selectedOptions.label" )#</small></p>
	<select class="#inputClass# #extraClasses# to"
	        name="#inputName#_to"
	        id="#inputId#_to"
	        tabindex="#getNextTabIndex()#"
	        multiple="multiple"
	        size="#selectSize#"
	>
		<cfloop array="#values#" index="i" item="selectedValue">
			<cfset selected = ListFindNoCase( value, selectedValue ) />

			<cfif isTrue( selected )>
				<option value="#HtmlEditFormat( selectedValue )#">
					#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
				</option>
			</cfif>
		</cfloop>
	</select>
</cfoutput>