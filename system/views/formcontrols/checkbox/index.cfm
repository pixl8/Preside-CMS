<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	labels       = args.checkboxLabel ?: "";
	value        = event.getValue( name=inputName, defaultValue=defaultValue );

	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<div class="checkbox">
		<label>
			<input type="checkbox" id="#inputId#" name="#inputName#" value="#value#" class="#inputClass#" tabindex="#getNextTabIndex()#">
			#labels#
		</label>
	</div>
</cfoutput>