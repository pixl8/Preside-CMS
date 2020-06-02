<cfscript>
	content    = args.content ?: "";
	activeTab  = IsTrue( args.treeView ?: "" ) ? "tree" : "grid";
	objectName = args.objectName ?: "";
	treeLink   = event.buildAdminLink( objectName=objectName, queryString="tab=tree" );
	gridLink   = event.buildAdminLink( objectName=objectName, queryString="tab=grid" );
</cfscript>

<cfoutput>
	<ul class="nav nav-tabs">
		<li<cfif activeTab == "tree"> class="active"</cfif>>
			<a<cfif activeTab != "tree"> href="#treeLink#"</cfif>>
				<i class="fa fa-fw fa-sitemap green"></i>
				#translateResource( "cms:datamanager.tree.view" )#
			</a>
		</li>
		<li<cfif activeTab != "tree"> class="active"</cfif>>
			<a<cfif activeTab == "tree"> href="#gridLink#"</cfif>>
				<i class="fa fa-fw fa-table blue"></i>
				#translateResource( "cms:datamanager.grid.view" )#
			</a>
		</li>
	</ul>
	<div class="tab-content">
		<div class="tab-pane active">
			#content#
		</div>
	</div>
</cfoutput>