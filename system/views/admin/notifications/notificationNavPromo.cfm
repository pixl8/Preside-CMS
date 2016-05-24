<cfscript>
	notificationCount = args.notificationCount   ?: 0;
	notifications     = args.latestNotifications ?: QueryNew('');
</cfscript>


<cfoutput>
	<a href="##" class="dropdown-toggle" data-toggle="dropdown">
		<i class="fa fa-bell-o<cfif notificationCount> icon-animated-bell</cfif>"></i>
		<span class="badge <cfif notificationCount>badge-important</cfif>">#notificationCount#</span>
	</a>

	<ul class="pull-right dropdown-navbar dropdown-menu dropdown-caret dropdown-close">
		<li class="dropdown-header">
			<cfif notificationCount>
				<i class="icon-warning-sign"></i>
				#translateResource( uri="cms:notifications.navpromo.count", data=[ notificationCount ] )#
			<cfelse>
				<i class="icon-check"></i>
				#translateResource( "cms:notifications.navpromo.no.new.notifications" )#
			</cfif>
		</li>

		<cfloop query="notifications">
			<li>
				<a href="#event.buildAdminLink( linkTo="notifications", queryString="topic=#notifications.topic#" )#">
					<div class="clearfix">
						<span class="pull-left">
							<i class="fa fa-fw #translateResource( 'notifications.#notifications.topic#:iconClass', 'fa-bell' )#"></i>
							#translateResource( 'notifications.#notifications.topic#:title', notifications.topic )#
						</span>
						<span class="pull-right badge badge-info">#notifications.notification_count#</span>
					</div>
				</a>
			</li>
		</cfloop>

		<li>
			<a href="#event.buildAdminLink( linkTo="notifications" )#">
				#translateResource( 'cms:notifications.navpromo.link.title' )#
				<i class="icon-arrow-right"></i>
			</a>
		</li>
	</ul>
</cfoutput>