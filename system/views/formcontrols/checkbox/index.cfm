<!---@feature presideForms--->
<cfscript>
	inputName    = args.name          ?: "";
	inputId      = args.id            ?: "";
	inputClass   = args.class         ?: "";
	defaultValue = args.defaultValue  ?: "";
	labels       = !isEmptyString( args.checkboxLabel ?: "" ) ? translateResource( args.checkboxLabel ?: "", args.checkboxLabel ?: "" ) : ( args.label ?: "" );
	value        = event.getValue( name=inputName, defaultValue=defaultValue );
	checked      = isTrue( value );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<div class="checkbox">
		<label>
			<input type="checkbox" id="#inputId#" name="#inputName#" value="1" class="#inputClass#" tabindex="#getNextTabIndex()#" <cfif checked>checked</cfif> #htmlAttributes# />
			#labels#
		</label>
	</div>
</cfoutput>
