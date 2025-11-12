<cfscript>
	inputName  = args.name     ?: "";
	inputId    = args.id       ?: "";
	inputClass = args.class    ?: "";
	disabled   = args.disabled ?: false;

	defaultValue = args.defaultValue ?: 0;

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) { value = ""; }
	value = EncodeForHtmlAttribute( value );

	labels = len( args.labels ) ? args.labels : args.values;
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }

	values = args.values ?: "";
	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }

	toggleFields        = args.toggleFields        ?: "";
	toggleDefaultFields = args.toggleDefaultFields ?: "";
</cfscript>

<cfoutput>
	<cfloop array="#values#" index="i" item="selectValue">
		<cfset isChecked  = ListFindNoCase( value, selectValue ) />
		<cfset elementId  = inputId & "_" & i />

		<div class="radio">
			<input
				type="radio"
				id="#elementId#"
				name="#inputName#"
				value="#EncodeForHtmlAttribute( selectValue )#"
				class="#inputClass#"
				data-toggle-fields="#toggleFields#"
				data-toggle-default-fields="#toggleDefaultFields#"
				tabindex="#getNextTabIndex()#"
				<cfif disabled>disabled="disabled"</cfif>
				<cfif isChecked> checked="checked"</cfif>
			>
			<label for="#elementId#">#EncodeForHtmlAttribute( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#</label>
		</div>
	</cfloop>
</cfoutput>