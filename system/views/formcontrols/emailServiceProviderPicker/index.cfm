<!---@feature admin and emailCenter--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	items        = args.providers    ?: ArrayNew(1)
	multiple     = IsTrue( args.multiple ?: "" );
	inputType    = multiple ? "checkbox" : "radio";

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
	<cfloop array="#items#" index="item">
		<cfset itemId = inputId & LCase( Hash( item.id ) ) />
		<div class="checkbox role-picker-#inputType#">
			<label>
				<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#itemId#" type="#inputType#" value="#HtmlEditFormat( item.id )#"<cfif value == item.id> checked="checked"</cfif> tabindex="#getNextTabIndex()#" #htmlAttributes# />
				<span class="lbl">
					<span class="role-title bigger">#item.title#</span><br />
					<span class="role-desc">#item.description#</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>
