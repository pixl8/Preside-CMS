<cfscript>
	inputName  = args.name  ?: "";
	inputId    = args.id    ?: "";
	inputClass = args.class ?: "";

	defaultValue = args.defaultValue ?: 0;

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) { value = ""; }
	value = EncodeForHtmlAttribute( value );

	isChecked  = isTrue( value );
	isDisabled = isTrue( args.disabled ?: false );

	toggleFields        = args.toggleFields        ?: "";
	toggleDefaultFields = args.toggleDefaultFields ?: "";
</cfscript>

<cfoutput>
	<input
		type="checkbox"
		id="#inputId#"
		name="#inputName#"
		value="1"
		class="ace ace-switch ace-switch-6 #inputClass#"
		data-toggle-fields="#toggleFields#"
		data-toggle-default-fields="#toggleDefaultFields#"
		tabindex="#getNextTabIndex()#"
		<cfif isChecked> checked="checked"</cfif>
		<cfif isDisabled> disabled="disabled"</cfif>
	>
	<span class="lbl"></span>
</cfoutput>