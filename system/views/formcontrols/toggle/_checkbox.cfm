<cfscript>
	inputName  = args.name  ?: "";
	inputId    = args.id    ?: "";
	inputClass = args.class ?: "";

	defaultValue = args.defaultValue ?: 0;

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) { value = ""; }
	value = EncodeForHtmlAttribute( value );

	labels = !isEmptyString( args.checkboxLabel ?: "" ) ? translateResource( args.checkboxLabel, args.checkboxLabel ) : ( args.label ?: "" );

	isChecked  = isTrue( value );
	isDisabled = isTrue( args.disabled ?: false );

	toggleFields        = args.toggleFields        ?: "";
	toggleDefaultFields = args.toggleDefaultFields ?: "";
</cfscript>

<cfoutput>
	<div class="checkbox">
		<input
			type="checkbox"
			id="#inputId#"
			name="#inputName#"
			value="1"
			class="#inputClass#"
			data-toggle-fields="#toggleFields#"
			data-toggle-default-fields="#toggleDefaultFields#"
			tabindex="#getNextTabIndex()#"
			<cfif isChecked> checked="checked"</cfif>
			<cfif isDisabled> disabled="disabled"</cfif>
		>
		<label for="#inputId#">#labels#</label>
	</div>
</cfoutput>