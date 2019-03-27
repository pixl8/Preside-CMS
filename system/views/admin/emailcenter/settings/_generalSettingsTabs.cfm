<cfparam name="args.body"                   default="" />
<cfparam name="args.tab"                    default="general" />
<cfparam name="args.providers" type="array" default="#ArrayNew(1)#" />

<cfscript>
	templateId = rc.id      ?: "";
	version    = rc.version ?: "";
	tabs       = [];

	tabs.append({
		  id     = "general"
		, icon   = "fa-cogs grey"
		, title  = translateResource( "cms:emailcenter.settings.tab.general" )
		, active = ( args.tab == "general" )
		, link   = ( args.tab == "general" ) ? "" : event.buildAdminLink( linkTo="emailcenter.settings" )
	});

	for( var provider in args.providers ) {
		tabs.append({
			  id     = "provider-" & provider.id
			, icon   = provider.iconClass
			, title  = provider.title
			, active = ( args.tab == provider.id )
			, link   = ( args.tab == provider.id ) ? "" : event.buildAdminLink( linkTo="emailcenter.settings.provider", queryString="id=" & provider.id )
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