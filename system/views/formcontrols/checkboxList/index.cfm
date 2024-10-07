<!---@feature presideForms--->
<cfscript>
	inputName      = args.name            ?: "";
	inputId        = args.id              ?: "";
	inputClass     = args.class           ?: "";
	values         = args.values          ?: "";
	defaultValue   = args.defaultValue    ?: "";
	extraClasses   = args.extraClasses    ?: "";
	values         = args.values          ?: "";
	labels         = len( args.labels )   ?  args.labels : args.values;

	if ( IsSimpleValue( values ) ) { values = ListToArray( values ); }
	if ( IsSimpleValue( labels ) ) { labels = ListToArray( labels ); }

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
	valueFound = false;

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<cfloop array="#values#" index="i" item="selectValue">
		<cfset checked    = ListFindNoCase( value, selectValue ) />
		<cfset valueFound = valueFound || checked />
		<cfset elementId  = inputId & "_" & i />

		<div class="checkbox">
			<label>
				<input type="checkbox" id="#elementId#" name="#inputName#" value="#HtmlEditFormat( selectValue )#" class="#inputClass# #extraClasses#" tabindex="#getNextTabIndex()#" <cfif checked>checked</cfif> #htmlAttributes# />
				#HtmlEditFormat( translateResource( labels[i] ?: "", labels[i] ?: "" ) )#
			</label>
		</div>
	</cfloop>
	<label for="#inputName#" class="error"></label>
</cfoutput>
