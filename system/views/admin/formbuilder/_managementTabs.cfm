<cfscript>
	activeTab       = args.activeTab ?: "manage";
	canEdit         = IsTrue( args.canEdit ?: "" );
	canEditActions  = IsTrue( args.canEditActions ?: "" );
	tabs            = [];
	formId          = rc.id ?: "";
	submissionCount = args.submissionCount ?: 0;
	actionCount     = args.actionCount     ?: 0;

	if ( canEdit ) {
		tabs.append({
			  icon   = "fa-reorder"
			, active = ( activeTab == "manage" )
			, link   = event.buildAdminLink( linkto="formbuilder.manageform", queryString="id=#formId#" )
			, title  = translateResource( "formbuilder:management.tabs.fields.title" )
		});
	}

	if ( canEditActions ) {
		tabs.append({
			  icon   = "fa-send"
			, active = ( activeTab == "actions" )
			, link   = event.buildAdminLink( linkto="formbuilder.actions", queryString="id=#formId#" )
			, title  = translateResource( uri="formbuilder:management.tabs.actions.title", data=[ NumberFormat( actionCount ) ] )
		});
	}

	tabs.append({
		  icon   = "fa-users"
		, active = ( activeTab == "submissions" )
		, link   = event.buildAdminLink( linkto="formbuilder.submissions", queryString="id=#formId#" )
		, title  = translateResource( uri="formbuilder:management.tabs.submissions.title", data=[ NumberFormat( submissionCount ) ] )
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