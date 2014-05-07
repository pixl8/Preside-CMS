<cfoutput>
	<div class="navbar navbar-default" id="navbar">
		<script type="text/javascript">
			try{ace.settings.check('navbar' , 'fixed')}catch(e){}
		</script>

		<div class="navbar-container" id="navbar-container">
			<div class="navbar-header pull-left">
				<a href="##" class="navbar-brand">#translateResource( uri="cms:cms.title" )#</a>
			</div><!-- /.navbar-header -->

			<div class="navbar-header pull-right" role="navigation">
				<ul class="nav ace-nav">
					<li>
						<a data-toggle="dropdown" href="##" class="dropdown-toggle">
							<img class="nav-user-photo" src="http://www.gravatar.com/avatar/#LCase( Hash( LCase( event.getAdminUserDetails().emailAddress ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( event.getAdminUserDetails().knownAs )#" />
							<span class="user-info"> #event.getAdminUserDetails().knownAs# </span>

							<i class="fa fa-caret-down"></i>
						</a>

						<ul class="user-menu pull-right dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
							<li>
								<a href="##">
									<i class="fa fa-cog"></i>
									Settings
								</a>
							</li>

							<li>
								<a href="##">
									<i class="fa fa-user"></i>
									Profile
								</a>
							</li>

							<li class="divider"></li>

							<li>
								<a href="#event.buildAdminLink( linkTo="login.logout" )#">
									<i class="fa fa-off"></i>
									Logout
								</a>
							</li>
						</ul>
					</li>
					<li>
						<a href="#getSetting( 'presideHelpAndSupportLink' )#">#translateResource( "cms:helpandsupport.link" )#</a>
					</li>
				</ul><!-- /.ace-nav -->
			</div><!-- /.navbar-header -->
		</div><!-- /.container -->
	</div>
</cfoutput>