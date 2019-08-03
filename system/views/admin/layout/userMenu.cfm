<cfscript>
	if ( event.isAdminRequest() ) {
		logoutUrl = event.buildAdminLink( linkTo="login.logout" );
	} else {
		logoutUrl = event.buildAdminLink( linkTo="login.logout", queryString="redirect=referer" );
	}
</cfscript>

<cfoutput>
	<a data-toggle="preside-dropdown" href="##" class="dropdown-toggle">
		<img class="nav-user-photo user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( event.getAdminUserDetails().email_address ) ) )#?r=g&d=mm&s=40" alt="" />
		<span class="user-info"> #event.getAdminUserDetails().known_as# </span>

		<i class="fa fa-caret-down"></i>
	</a>

	<ul class="user-menu dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
		<li>
			<a href="#event.buildAdminLink( linkTo="editProfile" )#">
				<i class="fa fa-user"></i>
				#translateResource( "cms:editProfile.link" )#
			</a>
		</li>
		<li>
			<a href="#logoutUrl#">
				<i class="fa fa-sign-out"></i>
				#translateResource( "cms:logout.link" )#
			</a>
		</li>
	</ul>
</cfoutput>