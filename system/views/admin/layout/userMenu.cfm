<cfoutput>
	<a data-toggle="dropdown" href="##" class="dropdown-toggle">
		<img class="nav-user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( event.getAdminUserDetails().email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( event.getAdminUserDetails().known_as )#" />
		<span class="user-info"> #event.getAdminUserDetails().known_as# </span>

		<i class="fa fa-caret-down"></i>
	</a>

	<ul class="user-menu pull-right dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
		<li>
			<a href="#event.buildAdminLink( linkTo="editProfile" )#">
				<i class="fa fa-user"></i>
				#translateResource( "cms:editProfile.link" )#
			</a>
		</li>
		<li>
			<a href="#event.buildAdminLink( linkTo="login.logout" )#">
				<i class="fa fa-sign-out"></i>
				#translateResource( "cms:logout.link" )#
			</a>
		</li>
	</ul>
</cfoutput>