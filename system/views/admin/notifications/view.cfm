<cfscript>
	notification = prc.notification ?: {};
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline confirmation-prompt" href="#event.buildAdminLink( linkTo="notifications.dismissAction", queryString="id=#notification.id#")#" data-global-key="d" title="#translateResource( 'cms:notifications.discard.prompt' )#">
			<button class="btn btn-danger btn-sm">
				<i class="fa fa-trash"></i>
				#translateResource( "cms:notifications.dismiss.btn" )#
			</button>
		</a>
	</div>

	#renderNotification( notification.topic, notification.data, "full" )#

</cfoutput>