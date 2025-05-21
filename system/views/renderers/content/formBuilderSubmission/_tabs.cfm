<cfparam name="args.tabs"      type="array" default=[] />
<cfparam name="args.responses" type="array" default=[] />

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs" role="tablist">
			<cfloop array="#args.tabs#" index="i" item="tab">
				<li role="presentation" class="<cfif i eq 1>active</cfif>">
					<a data-toggle="tab" href="##tab-#i#">
						#tab.configuration.label#
					</a>
				</li>
			</cfloop>
		</ul>

		<div class="tab-content">
			<cfloop array="#args.responses#" index="i" item="response">
				<div id="tab-#i#" class="tab-pane<cfif i eq 1> active</cfif>">
					#response#
				</div>
			</cfloop>
		</div>
	</div>
</cfoutput>