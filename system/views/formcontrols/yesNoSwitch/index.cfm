<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	disabled     = isTrue( args.disabled ?: "" );

	switchClass = args.switchClass ?: "ace-switch ace-switch-6";
	switchLabel = args.switchLabel ?: "";
	switchLabel = translateResource( uri=switchLabel, defaultValue=switchLabel );
	switchDesc  = args.switchDesc ?: "";
	switchDesc  = translateResource( uri=switchDesc, defaultValue=switchDesc );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	checked = IsBoolean( value ) && value;

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<cfif Len( Trim( switchLabel & switchDesc ) )>
		<div class="checkbox role-picker-radio">
			<label>
	</cfif>

	<input class="#inputClass# ace #switchClass#" type="checkbox" id="#inputId#" name="#inputName#"<cfif checked> checked="checked"</cfif> value="1" tabindex="#getNextTabIndex()#" <cfif disabled> disabled</cfif> #htmlAttributes#>
	<span class="lbl">
		<cfif Len( Trim( switchLabel ) )>
			<span class="role-title bigger">#switchLabel#</span>
		</cfif>
		<cfif Len( Trim( switchDesc ) )>
			<br />
			<span class="role-desc">#switchDesc#</span>
		</cfif>
	</span>

	<cfif Len( Trim( switchLabel & switchDesc ) )>
			</label>
		</div>
	</cfif>
</cfoutput>
