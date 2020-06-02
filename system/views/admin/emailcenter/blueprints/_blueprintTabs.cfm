<cfparam name="args.body"                               default="" />
<cfparam name="args.tab"                                default="preview" />
<cfparam name="args.canEdit"             type="boolean" default="false" />
<cfparam name="args.canConfigureLayout"  type="boolean" default="false" />

<cfscript>
	blueprintId = rc.id ?: "";
	tabs        = [];

	tabs.append({
		  id     = "preview"
		, icon   = "fa-eye blue"
		, title  = translateResource( "cms:emailcenter.blueprints.blueprint.tab.preview" )
		, active = ( args.tab == "preview" )
		, link   = ( args.tab == "preview" ) ? "" : event.buildAdminLink( linkTo="emailcenter.blueprints.preview", queryString="id=#blueprintId#" )
	});

	if ( args.canEdit ) {
		tabs.append({
			  id     = "edit"
			, icon   = "fa-pencil green"
			, title  = translateResource( "cms:emailcenter.blueprints.blueprint.tab.edit" )
			, active = ( args.tab == "edit" )
			, link   = ( args.tab == "edit" ) ? "" : event.buildAdminLink( linkTo="emailcenter.blueprints.edit", queryString="id=#blueprintId#" )
		});
	}

	if ( args.canConfigureLayout ) {
		tabs.append({
			  id     = "layout"
			, icon   = "fa-code"
			, title  = translateResource( "cms:emailcenter.blueprints.blueprint.tab.layout" )
			, active = ( args.tab == "layout" )
			, link   = ( args.tab == "layout" ) ? "" : event.buildAdminLink( linkTo="emailcenter.blueprints.configurelayout", queryString="id=" & blueprintId )
		});
	}
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<cfloop array="#tabs#" index="i" item="tab">
				<li <cfif tab.active>class="active"</cfif>>
					<a href="#tab.link#">
						<i class="fa fa-fw #tab.icon#"></i>&nbsp;
						#tab.title#
					</a>
				</li>
			</cfloop>
		</ul>
		<div class="tab-content">
			<div class="tab-pane active">#args.body#</div>
		</div>
	</div>
</cfoutput>