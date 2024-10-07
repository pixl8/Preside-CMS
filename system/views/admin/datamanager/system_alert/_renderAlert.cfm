<!---@feature admin--->
<cfscript>
	alert    = args.alert     ?: {};
	rendered = alert.rendered ?: "";
</cfscript>

<cfoutput>
	<div class="widget-box system-alert-widget system-alert-widget-#alert.level#">
		<div class="widget-header">
			<h4 class="widget-title lighter smaller">
				#renderContent( "systemAlertType", alert.type )#
			</h4>
		</div>

		<div class="widget-body">
			<div class="widget-main padding-20">
				#rendered#
			</div>
		</div>
	</div>
</cfoutput>