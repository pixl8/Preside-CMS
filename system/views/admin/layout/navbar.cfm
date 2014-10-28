<cfoutput>
	<div class="navbar navbar-default" id="navbar">
		<script type="text/javascript">
			try{ace.settings.check('navbar' , 'fixed')}catch(e){}
		</script>

		<div class="navbar-container" id="navbar-container">
			<div class="navbar-header pull-left">
				<a href="##" class="navbar-brand">#translateResource( uri="cms:cms.title" )#</a>
			</div><!-- /.navbar-header -->

			#renderViewlet( "admin.sites.sitePicker" )#

			<div class="navbar-header pull-right" role="navigation">
				<ul class="nav ace-nav">
					<li>
						<a data-toggle="dropdown" href="##" class="dropdown-toggle">
							<img class="nav-user-photo" src="http://www.gravatar.com/avatar/#LCase( Hash( LCase( event.getAdminUserDetails().email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( event.getAdminUserDetails().known_as )#" />
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