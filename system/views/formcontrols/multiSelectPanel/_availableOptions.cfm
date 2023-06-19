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
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<p><small>#translateResource( "formcontrols.multiSelectPanel:availableOptions.label" )#</small></p>
	<select class="#inputClass# #extraClasses# from"
			name="#inputName#_from"
			id="#inputId#_from"
			tabindex="#getNextTabIndex()#"
			multiple="multiple"
			size="#selectSize#"
			#htmlAttributes#
	>
		<cfloop array="#values#" index="i" item="availableValue">
			<cfset selected = ListFindNoCase( value, availableValue ) />

			<cfif isFalse( selected )>
				<option value="#HtmlEditFormat( availableValue )#">
					#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
				</option>
			</cfif>
		</cfloop>
	</select>
</cfoutput>
