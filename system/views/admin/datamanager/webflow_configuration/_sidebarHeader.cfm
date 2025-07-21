<cfscript>
	recordDetail   = args.record              ?: {};
	recordLabel    = recordDetail.label       ?: "";
	recordDesc     = recordDetail.description ?: "";
	hideFromWidget = isTrue( recordDetail.hide_from_widget ?: "" );
	completionRate = Val( recordDetail.instance_completion_rate ?: "" );
</cfscript>

<cfoutput>
	<p class="text-muted">
		#renderContent( "boolean", !hideFromWidget, "admin" )#
		#translateResource( uri="preside-objects.webflow_configuration:sidebar.header.hide_from_widget.#hideFromWidget ? "yes" : "no"#.label" )#
	</p>

	<cfif completionRate GT 0>
		<p>
			<i class="fa fa-fw #translateResource( uri="preside-objects.webflow_configuration:sidebar.header.instance_completion_rate.iconClass" )#"></i>
			#translateResource( uri="preside-objects.webflow_configuration:sidebar.header.instance_completion_rate.label", data=[ completionRate ] )#
		</p>
	</cfif>

	<h2>
		<i class="fa fa-fw #translateResource( uri="preside-objects.webflow_configuration:iconClass" )#"></i>
		#recordLabel#
	</h2>

	<cfif Len( recordDesc )>
		<p>#recordDesc#</p>
	</cfif>
</cfoutput>