<!---@feature admin and sitetree--->
<cfscript>
	site = event.getSite();

	prc.pageIcon    = "sitemap";
	prc.pageTitle   = site.name ?: translateResource( "cms:sitetree" );
	rc.id           = "page";
	args.objectName = "page";

	activeTree          = prc.activeTree ?: [];
	trashCount          = prc.trashCount ?: 0;
	validTabs           = [ "sitetree", "listing" ];
	activeTab           = rc.tab ?: "sitetree";
	if ( !ArrayFindNoCase( validTabs, activeTab ) ) {
        activeTab = "sitetree";
    }
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<li<cfif activeTab=="sitetree"> class="active"</cfif>>
				<a href="##tab-sitetree" data-toggle="tab" >
					<i class="fa fa-fw fa-sitemap" title="#translateResource( "cms:sitetree" )#"></i>
					#translateResource( "cms:sitetree" )#
				</a>
			</li>
			<li<cfif activeTab=="listing"> class="active"</cfif>>
				<a href="##tab-page" data-toggle="tab" >
					<i class="fa fa-fw fa-list-alt" title="#translateResource( "cms:sitetree.listing.title" )#"></i>
					#translateResource( "cms:sitetree.listing.title" )#
				</a>
			</li>
		</ul>
		<div class="tab-content">
			<div class="tab-pane<cfif activeTab=="sitetree"> active</cfif>" id="tab-sitetree">
				#renderView( view="/admin/sitetree/_treeIndex", args=args )#
			</div>
			<div class="tab-pane<cfif activeTab=="listing"> active</cfif>" id="tab-page">
				#objectDataTable( objectName="page" )#
			</div>
		</div>
	</div>
</cfoutput>