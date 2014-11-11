<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	defaultValue = args.defaultValue ?: "";
	topics       = args.topics  ?: ArrayNew(1);

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<cfloop array="#topics#" index="topic">
		<div class="checkbox role-picker-checkbox">
			<label>
				<input class="ace ace-switch ace-switch-3" name="#inputName#" id="#inputId#-#topic#" type="checkbox" class="ace" value="#topic#"<cfif ListFindNoCase( value, topic )> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
				<span class="lbl">
					<span class="role-title bigger">#translateResource( 'notifications.#topic#:title', topic )#</span><br />
					<span class="role-desc">#translateResource( 'notifications.#topic#:description', "" )#</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>