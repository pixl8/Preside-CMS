<cfscript>
	event.include( "/js/admin/specific/notifications/" );

	notificationCount      = args.notificationCount   ?: 0;
</cfscript>


<cfoutput>
	<a href="##" class="dropdown-toggle" id="notificationBar" data-href="#event.buildAdminLink( linkTo="notifications.getAjaxUnreadTopics" )#"  data-container="##notificationDropDown" data-toggle="preside-dropdown">
		<i class="fa fa-bell-o<cfif notificationCount> icon-animated-bell</cfif>"></i>
		<span class="badge <cfif notificationCount>badge-important</cfif>">#notificationCount#</span>
	</a>

	<ul class="dropdown-navbar dropdown-menu dropdown-caret dropdown-close" id="notificationDropDown">
		<li class="dropdown-header">
			<cfif notificationCount>
				<i class="icon-warning-sign"></i>
				#translateResource( uri="cms:notifications.navpromo.count", data=[ notificationCount ] )#
			<cfelse>
				<i class="icon-check"></i>
				#translateResource( "cms:notifications.navpromo.no.new.notifications" )#
			</cfif>
		</li>
		<li>
			<a href="#event.buildAdminLink( linkTo="notifications" )#">
				#translateResource( 'cms:notifications.navpromo.link.title' )#
				<i class="icon-arrow-right"></i>
			</a>
		</li>
	</ul>
</cfoutput>