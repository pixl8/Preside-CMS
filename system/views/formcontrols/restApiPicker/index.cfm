<!---@feature presideForms and apiManager--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	apis         = args.apis         ?: ArrayNew(1);

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<cfloop array="#apis#" index="api">
		<div class="checkbox role-picker-checkbox">
			<label>
				<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#inputId#-#api.id#" type="checkbox"  value="#HtmlEditFormat( api.id )#"<cfif ListFindNoCase( value, api.id )> checked="checked"</cfif> tabindex="#getNextTabIndex()#" #htmlAttributes# />
				<span class="lbl">
					<span class="role-title bigger">
						#api.id#
					</span><br />
					<span class="role-desc">
						#api.description#
					</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>
