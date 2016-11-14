<cfparam name="args.body" default="" />
<cfparam name="args.tab"  default="preview" />

<cfscript>
	layoutId     = rc.layout ?: "";
	layout       = prc.layout ?: {};
	configurable = IsTrue( layout.configurable ?: "" ) && hasCmsPermission( "emailcenter.layouts.configure" );
	tabs         = [];

	tabs.append({
		  id     = "preview"
		, icon   = "fa-eye blue"
		, title  = translateResource( "cms:emailcenter.layouts.layout.tab.preview" )
		, active = ( args.tab == "preview" )
		, link   = ( args.tab == "preview" ) ? "" : event.buildAdminLink( linkTo="emailcenter.layouts.layout", queryString="layout=#layoutId#" )
	});

	if ( configurable ) {
		tabs.append({
			  id     = "layout"
			, icon   = "fa-cogs grey"
			, title  = translateResource( "cms:emailcenter.layouts.layout.tab.configure" )
			, active = ( args.tab == "configure" )
			, link   = ( args.tab == "configure" ) ? "" : event.buildAdminLink( linkTo="emailcenter.layouts.configure", queryString="layout=" & layoutId )
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