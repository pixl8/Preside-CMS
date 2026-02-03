<!---@feature presideForms and websiteUsers--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	permissions  = args.permissions  ?: ArrayNew(1);

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
	<cfloop array="#permissions#" index="perm">
		<div class="checkbox role-picker-checkbox">
			<label>
				<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#inputId#-#perm.id#" type="checkbox" value="#perm.id#"<cfif ListFindNoCase( value, perm.id )> checked="checked"</cfif> tabindex="#getNextTabIndex()#" #htmlAttributes# />
				<span class="lbl">
					<span class="role-title bigger">#perm.title#</span><br />
					<span class="role-desc">#perm.description#</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>
