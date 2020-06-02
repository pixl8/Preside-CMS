<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	items        = args.items        ?: ArrayNew(1)

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<cfloop array="#items#" index="item">
		<cfset itemId = inputId & LCase( Hash( item.id ) ) />
		<div class="checkbox role-picker-radio">
			<label>
				<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#itemId#" type="radio" value="#HtmlEditFormat( item.id )#"<cfif value == item.id> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
				<span class="lbl">
					<span class="role-title bigger">#item.label#</span><br />
					<span class="role-desc">#item.description#</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>