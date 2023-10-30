<cfscript>
	site = event.getSite();

	prc.pageIcon    = "sitemap";
	prc.pageTitle   = site.name ?: translateResource( "cms:sitetree" );
	rc.id           = "page";
	args.objectName = "page";

	activeTree          = prc.activeTree ?: [];
	trashCount          = prc.trashCount ?: 0;
	activeTab           = rc.tab ?: "sitetree";
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<li<cfif activeTab=="sitetree"> class="active"</cfif>>
				<a href="##tab-sitetree" data-toggle="tab" >
					<i class="fa fa-fw fa-sitemap" title="#HtmlEditFormat( prc.pageTitle )#"></i>&nbsp;

					<span class="hidden-xs">
						#prc.pageTitle#
					</span>
				</a>
			</li>
			<li<cfif activeTab=="page"> class="active"</cfif>>
				<a href="##tab-page" data-toggle="tab" >
					<i class="fa fa-fw fa-list-alt" title="#translateResource( "cms:sitetree.listing.title" )#"></i>&nbsp;

					<span class="hidden-xs">
						#prc.pageTitle#: #translateResource( "cms:sitetree.listing.title" )#
					</span>
				</a>
			</li>
		</ul>
		<div class="tab-content">
			<div class="tab-pane<cfif activeTab=="sitetree"> active</cfif>" id="tab-sitetree">
				#renderView( view="/admin/sitetree/__treeIndex", args=args )#
			</div>
			<div class="tab-pane<cfif activeTab=="page"> active</cfif>" id="tab-page">
				#renderView( view="/admin/sitetree/__altIndex", args=args )#
			</div>
		</div>
	</div>
</cfoutput>
<!---

<cfscript>
	site = event.getSite();

	prc.pageIcon  = "sitemap";
	prc.pageTitle = site.name ?: translateResource( "cms:sitetree" );

	activeTree          = prc.activeTree ?: [];
	trashCount          = prc.trashCount ?: 0;
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif hasCmsPermission( permissionKey="sites.manage" )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="sites.editSite", queryString="id=" & site.id )#">
				<button class="btn btn-sm">
					<i class="fa fa-cogs"></i>
					#translateResource( 'cms:sitetree.edit.site.settings.btn' )#
				</button>
			</a>
		</cfif>
		<cfif isFeatureEnabled( "fullPageCaching" ) && hasCmsPermission( permissionkey="sitetree.clearcaches" )>
			<a class="pull-right inline confirmation-prompt" href="#event.buildAdminLink( linkTo="sitetree.clearPageCacheAction" )#" title="#HtmlEditFormat( translateResource( "cms:sitetree.flush.cache.prompt" ) )#">
				<button class="btn btn-sm btn-warning">
					<i class="fa fa-refresh"></i>
					#translateResource( 'cms:sitetree.flush.cache.btn' )#
				</button>
			</a>
		</cfif>
	</div>

	<div class="info-bar">#renderViewlet( event='admin.sitetree.searchBox' )#</div>

	<table class="table table-striped table-hover tree-table">
		<thead>
			<tr>
				<th>#translateResource( 'cms:sitetree.table.title.header'    )#</th>
				<th>#translateResource( 'cms:sitetree.table.pagetype.header' )#</th>
				<th>#translateResource( 'cms:sitetree.table.status.header'   )#</th>
				<th>#translateResource( 'cms:sitetree.table.access.header'   )#</th>
				<th>#translateResource( 'cms:sitetree.table.url.header'      )#</th>
			</tr>
		</thead>
		<tbody data-nav-list-child-selector="tr" data-nav-list="1">
			<cfloop array="#activeTree#" item="node" index="i">
				#renderView( view="/admin/sitetree/_node", args=node )#
			</cfloop>
		</tbody>
	</table>

	<cfif hasCmsPermission( permissionKey="sitetree.viewTrash" ) >
		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo='sitetree.trash' )#" class="pull-right red">
					<i class="fa fa-fw fa-trash fa-lg"></i>
					#translateResource( uri="cms:sitetree.trash.link.title", data=[ trashCount ] )#
				</a>
			</div>
		</div>
	</cfif>
</cfoutput> --->