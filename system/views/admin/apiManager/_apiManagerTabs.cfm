<cfparam name="args.body" default="" />
<cfparam name="args.tab"  default="preview" />

<cfscript>
	tabs = [{
		  id     = "apis"
		, icon   = "fa-code blue"
		, title  = translateResource( "cms:apiManager.tabs.apis" )
		, active = ( args.tab == "apis" )
		, link   = ( args.tab == "apis" ) ? "" : event.buildAdminLink( linkTo="apiManager" )
	},{
		  id     = "apis"
		, icon   = "fa-users green"
		, title  = translateResource( "cms:apiManager.tabs.users" )
		, active = ( args.tab == "users" )
		, link   = ( args.tab == "users" ) ? "" : event.buildAdminLink( linkTo="apiUserManager" )
	}];
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