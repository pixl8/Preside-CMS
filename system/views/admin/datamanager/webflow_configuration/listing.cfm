<!---@feature webflow--->
<cfscript>
	tabs = [ "webflow_configuration", "webflow_configuration_step" ];
	activeTab = rc.tab ?: "webflow_configuration";
	if ( !ArrayFindNoCase( tabs, activeTab ) ) {
		activeTab = "webflow_configuration";
	}
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<cfloop array="#tabs#" index="i" item="tab">
				<li<cfif tab.id eq activeTab> class="active"</cfif>>
					<a href="##tab-#tab.id#" data-toggle="tab" >
						<i class="fa fa-fw #tab.iconClass#" title="#HtmlEditFormat( tab.title )#"></i>&nbsp;

						<span class="hidden-xs">
							#tab.title#
						</span>
					</a>
				</li>
			</cfloop>
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