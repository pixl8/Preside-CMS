<cfscript>
	configItems = getSetting( "adminConfigurationMenuItems" );
</cfscript>

<cfoutput>
	<cfsavecontent variable="settingsMenu">
		<cfloop array="#configItems#" item="item" index="i">
			#renderView( view="admin/layout/configurationMenu/#item#" )#
		</cfloop>
	</cfsavecontent>

	<div class="navbar navbar-default" id="navbar">
		<script type="text/javascript">
			try{ace.settings.check('navbar' , 'fixed')}catch(e){}
		</script>

		<div class="navbar-container" id="navbar-container">
			#renderViewlet( event="admin.layout.applicationNav", args={ selectedApplication="cms" } )#

			#renderViewlet( "admin.sites.sitePicker" )#

			<div class="navbar-header pull-right" role="navigation">
				<ul class="nav ace-nav">
					#renderViewlet( "admin.notifications.notificationNavPromo" )#

					<li>
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
					</li>
					<li>
						#renderViewlet( event='admin.Layout.localePicker' )#
					</li>
					<cfif Len( Trim( settingsMenu ) )>
						<li>
							<a data-toggle="dropdown" href="##" class="dropdown-toggle">
								<i class="fa fa-cogs"></i>
								#translateResource( "cms:configuration.menu.title" )#
								<i class="fa fa-caret-down"></i>
							</a>

							<ul class="pull-right dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
								#settingsMenu#
							</ul>
						</li>
					</cfif>

					<li>
						<a href="#getSetting( 'presideHelpAndSupportLink' )#">
							<i class="fa fa-life-ring"></i>
							#translateResource( "cms:helpandsupport.link" )#
						</a>
					</li>
				</ul><!-- /.ace-nav -->
			</div><!-- /.navbar-header -->
		</div><!-- /.container -->
	</div>
</cfoutput>