<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	items        = args.providers    ?: ArrayNew(1)
	multiple     = IsTrue( args.multiple ?: "" );
	inputType    = multiple ? "checkbox" : "radio";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<cfloop array="#items#" index="item">
		<cfset itemId = inputId & LCase( Hash( item.id ) ) />
		<div class="checkbox role-picker-#inputType#">
			<label>
				<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#itemId#" type="#inputType#" value="#HtmlEditFormat( item.id )#"<cfif value == item.id> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
				<span class="lbl">
					<span class="role-title bigger">#item.title#</span><br />
					<span class="role-desc">#item.description#</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>