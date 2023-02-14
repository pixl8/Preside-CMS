<cfscript>
	notifications = args.latestNotifications ?: QueryNew('');
</cfscript>

<cfoutput>
	<cfloop query="notifications">
		<li>
			<a href="#event.buildAdminLink( linkTo="notifications", queryString="topic=#notifications.topic#" )#">
				<div class="clearfix">
					<span class="pull-left">
						<i class="fa fa-fw #translateResource( 'notifications.#notifications.topic#:iconClass', 'fa-bell' )#"></i>
						#translateResource( 'notifications.#notifications.topic#:title', notifications.topic )#
					</span>
					<span class="pull-right badge badge-info">#notifications.notification_count lt getSetting( "notificationCountLimit" )?notifications.notification_count:( getSetting( "notificationCountLimit" )&"+" ) #</span>
				</div>
			</a>
		</li>
	</cfloop>
</cfoutput>