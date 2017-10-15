<cfscript>
	inputName    = args.name          ?: "";
	inputId      = args.id            ?: "";
	inputClass   = args.class         ?: "";
	defaultValue = args.defaultValue  ?: "";
	labels       = args.checkboxLabel ?: "";
	value        = event.getValue( name=inputName, defaultValue=defaultValue );
	checked      = isTrue( value );

	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<div class="checkbox">
		<label>
			<input type="checkbox" id="#inputId#" name="#inputName#" value="1" class="#inputClass#" tabindex="#getNextTabIndex()#" <cfif checked>checked</cfif> >
			#labels#
		</label>
	</div>
</cfoutput>