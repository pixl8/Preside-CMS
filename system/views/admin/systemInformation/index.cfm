<cfscript>
	renderedTab = prc.renderedTab;
	tabs        = prc.tabs ?: [];
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<cfloop array="#tabs#" index="i" item="tab">
				<li<cfif tab.active> class="active"</cfif>>
					<a href="#tab.link#">
						<i class="fa fa-fw #tab.iconClass#"></i>
						#tab.title#
					</a>
				</li>
			</cfloop>
		</ul>

		<div class="tab-content">
			<div class="tab-pane in active">
				#renderedTab#
			</div>
		</div>
	</div>
</cfoutput>