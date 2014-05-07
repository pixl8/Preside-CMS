<cfscript>
	postLoginUrl = event.getValue( name="postLoginUrl", defaultValue=event.buildAdminLink( linkto=getSetting( "adminDefaultEvent" ) ) );
</cfscript>

<cfoutput>
	<div class="center">
		<h1>
			<i class="fa fa-leaf green"></i>
			<span class="white">#translateResource( 'cms:cms.title' )#</span>
		</h1>
	</div>

	<div class="space-6"></div>


	<div class="position-relative">
		<div id="login-box" class="login-box visible widget-box no-border">
			<div class="widget-body">
				<div class="widget-main">
 					<h4 class="header blue lighter bigger">
						<i class="fa fa-keyboard green"></i>
						#translateResource( 'cms:login.prompt' )#
					</h4>

					<div class="space-6"></div>

					<form method="post" action="#event.buildAdminLink( linkto="login.login" )#" data-auto-focus-form="true">
						<fieldset>
							<input type="hidden" name="postLoginUrl" value="#postLoginUrl#" />

							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="text" class="form-control" placeholder="#translateResource( 'cms:login.username.placeholder' )#" name="loginId" value="#event.getValue( name="loginId", defaultValue="" )#" />
									<i class="fa fa-user"></i>
								</span>
							</label>

							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="password" class="form-control" placeholder="#translateResource( 'cms:login.password.placeholder' )#" name="password" />
									<i class="fa fa-lock"></i>
								</span>
							</label>

							<div class="space"></div>

							<div class="row-fluid">
								<button class="span4 btn btn-sm btn-primary">
									<i class="fa fa-key"></i>
									#translateResource( 'cms:login.button' )#
								</button>
							</div>
						</fieldset>
					</form>
				</div><!--/widget-main-->

				<div class="toolbar clearfix">
					<div>
						<a href="##forgot-box" class="forgot-password-link login-box-toggler">
							<i class="fa fa-arrow-left"></i>
							#translateResource( 'cms:login.forgotpw.link' )#
						</a>
					</div>
				</div>
			</div><!--/widget-body-->
		</div><!--/login-box-->

		<div id="forgot-box" class="forgot-box widget-box no-border">
			<div class="widget-body">
				<div class="widget-main">
					<h4 class="header red lighter bigger">
						<i class="fa fa-key"></i>
						#translateResource( 'cms:forgotpassword.title' )#<!--Retrieve Password-->
					</h4>

					<div class="space-6"></div>
					<p>
						#translateResource( 'cms:forgotpassword.prompt' )#<!--Enter your email and to receive instructions-->
					</p>

					<form>
						<fieldset>
							<input type="hidden" name="postLoginUrl" value="#postLoginUrl#" />
							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="text" class="form-control" placeholder="#translateResource( 'cms:forgotpassword.loginIdOrEmail.placeholder' )#" name="loginId" value="#event.getValue( name="loginId", defaultValue="" )#" />
									<i class="fa fa-user"></i>
								</span>
							</label>

							<div class="row-fluid">
								<button class="span10 offset2 btn btn-sm btn-danger">
									<i class="fa fa-envelope-alt"></i>
									#translateResource( 'cms:forgotpassword.button' )#
								</button>
							</div>
						</fieldset>
					</form>
				</div><!--/widget-main-->

				<div class="toolbar center">
					<a href="##login-box" class="back-to-login-link login-box-toggler">
						#translateResource( 'cms:forgotpassword.login.link' )#
						<i class="fa fa-arrow-right"></i>
					</a>
				</div>
			</div><!--/widget-body-->
		</div><!--/forgot-box-->


	</div><!--/position-relative-->
</cfoutput>