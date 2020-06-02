<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	topics       = args.topics  ?: ArrayNew(1);

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<div class="checkbox role-picker-checkbox">
		<label>
			<input class="#inputClass# ace ace-switch ace-switch-3 all-topics" name="#inputName#" id="#inputId#-all-topics" type="checkbox" value="all"<cfif ListFindNoCase( value, "all" )> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
			<span class="lbl">
				<span class="role-title bigger">#translateResource( 'cms:notifications.topics.control.alltopics.title' )#</span><br />
				<span class="role-desc">#translateResource( 'cms:notifications.topics.control.alltopics.description' )#</span>
			</span>
		</label>
	</div>

	<cfloop array="#topics#" index="topic">
		<div class="checkbox role-picker-checkbox">
			<label class="topic-checkbox-label">
				<input class="#inputClass# ace ace-switch ace-switch-3 topic-checkbox" name="#inputName#" id="#inputId#-#topic#" type="checkbox" value="#topic#"<cfif ListFindNoCase( value, "all" ) or ListFindNoCase( value, topic )> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
				<span class="lbl">
					<span class="role-title bigger">#translateResource( 'notifications.#topic#:title', topic )#</span><br />
					<span class="role-desc">#translateResource( 'notifications.#topic#:description', "" )#</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>