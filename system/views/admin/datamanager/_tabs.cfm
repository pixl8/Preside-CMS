<!---@feature admin--->
<cfscript>
	maxTabs = args.maxTabs ?: 6;
	tabs = args.tabs ?: [];
	activeTab = rc.tab ?: "";
	tabFound = false;
	activeTabIndex = 0;
	for( var tab in tabs ) {
		activeTabIndex++;
		if ( activeTab == tab.id ) {
			tabFound = true;
			break;
		}
	}

	if ( !tabFound ) {
		activeTabIndex = 1;
		activeTab = tabs[ 1 ].id ?: "";
	}
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<cfloop array="#tabs#" index="i" item="tab">
				<cfif i gt maxTabs>
					<cfbreak/>
				</cfif>
				<li<cfif tab.id eq activeTab> class="active"</cfif>>
					<a href="##tab-#tab.id#" data-toggle="tab" >
						<i class="fa fa-fw #tab.iconClass#" title="#HtmlEditFormat( tab.title )#"></i>&nbsp;

						<span class="hidden-xs">
							#tab.title#
						</span>
					</a>
				</li>
			</cfloop>

			<cfif ArrayLen( tabs ) gt maxTabs>
				<li role="presentation" class="dropdown<cfif activeTabIndex gt maxTabs> active</cfif>">
					<a class="dropdown-toggle" data-toggle="dropdown" href="##" role="button" aria-haspopup="true" aria-expanded="false">
						&hellip; <span class="caret"></span>
					</a>
					<ul class="dropdown-menu pull-right">
						<cfloop from="#( maxTabs + 1 )#" to="#ArrayLen( tabs )#" index="i">
							<cfset tab = tabs[ i ] />
							<li<cfif tab.id eq activeTab> class="active"</cfif>>
								<a href="##tab-#tab.id#" data-toggle="tab" >
									<i class="fa fa-fw #tab.iconClass#" title="#HtmlEditFormat( tab.title )#"></i>&nbsp;
									#tab.title#
								</a>
							</li>
						</cfloop>
					</ul>
				</li>
			</cfif>
		</ul>
		<div class="tab-content">
			<cfloop array="#tabs#" index="i" item="tab">
				<div class="tab-pane<cfif tab.id eq activeTab> active</cfif>" id="tab-#tab.id#">
					#tab.content#
				</div>
			</cfloop>
		</div>
	</div>
</cfoutput>