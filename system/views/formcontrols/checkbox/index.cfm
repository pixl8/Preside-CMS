<cfscript>
	inputName    = args.name          ?: "";
	inputId      = args.id            ?: "";
	inputClass   = args.class         ?: "";
	defaultValue = args.defaultValue  ?: "";
	labels       = !isEmptyString( args.checkboxLabel ?: "" ) ? translateResource( args.checkboxLabel ?: "", args.checkboxLabel ?: "" ) : ( args.label ?: "" );
	value        = event.getValue( name=inputName, defaultValue=defaultValue );
	checked      = isTrue( value );

	if ( !IsSimpleValue( value ) ) {
		value = "";
	}
	value = HtmlEditFormat( value );

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<div class="checkbox">
		<label>
			<input type="checkbox" id="#inputId#" name="#inputName#" value="1" class="#inputClass#" tabindex="#getNextTabIndex()#" <cfif checked>checked</cfif> #htmlAttributes# />
			#labels#
		</label>
	</div>
</cfoutput>
