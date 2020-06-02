<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	permissions  = args.permissions  ?: ArrayNew(1);

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<cfloop array="#permissions#" index="perm">
		<div class="checkbox role-picker-checkbox">
			<label>
				<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#inputId#-#perm.id#" type="checkbox" value="#perm.id#"<cfif ListFindNoCase( value, perm.id )> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
				<span class="lbl">
					<span class="role-title bigger">#perm.title#</span><br />
					<span class="role-desc">#perm.description#</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>