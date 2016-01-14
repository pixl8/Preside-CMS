<cfscript>
	activeTab = args.activeTab ?: "manage";
	canEdit   = IsTrue( args.canEdit ?: "" );
	tabs      = [];
	formId    = rc.id ?: "";

	tabs.append({
		  icon   = "fa-reorder"
		, active = ( activeTab == "manage" )
		, link   = event.buildAdminLink( linkto="formbuilder.manageform", queryString="id=#formId#" )
		, title  = translateResource( "formbuilder:management.tabs.fields.title" )
	});

	if ( canEdit ) {
		tabs.append({
			  icon   = "fa-cog"
			, active = ( activeTab == "settings" )
			, link   = event.buildAdminLink( linkto="formbuilder.editForm", queryString="id=#formId#" )
			, title  = translateResource( "formbuilder:management.tabs.settings.title" )
		});
	}
</cfscript>

<cfoutput>
	<ul class="nav nav-tabs">
		<cfloop array="#tabs#" item="tab" index="i">
			<li<cfif tab.active> class="active"</cfif>>
				<a<cfif !tab.active> href="#tab.link#"</cfif>>
					<i class="fa fa-fw #tab.icon#"></i>
					#tab.title#
				</a>
			</li>
		</cfloop>
	</ul>
</cfoutput>