<cfset notificationCount = args.notificationCount ?: 0 />

<cfoutput>
	<a href="#event.buildAdminLink( linkTo="notifications" )#" title="#HtmlEditFormat( translateResource( 'cms:notifications.navpromo.link.title' ) )#">
		<i class="fa fa-bell-o<cfif notificationCount> icon-animated-bell</cfif>"></i>
		<span class="badge <cfif notificationCount>badge-important</cfif>">#notificationCount#</span>
	</a>

</cfoutput>