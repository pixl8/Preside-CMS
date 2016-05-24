<cfscript>
	postLoginUrl = event.getValue( name="postLoginUrl", defaultValue="" );
	message      = rc.message ?: "";
</cfscript>

<cfoutput>
	<div class="position-relative">
		<div id="login-box" class="login-box visible widget-box no-border">
			<div class="widget-body">
				<div class="widget-main">
 					<h4 class="cms-brand">
						#translateResource( uri="cms:cms.title" )#
					</h4>

					<cfswitch expression="#message#">
						<cfcase value="LOGIN_FAILED">
							<div class="alert alert-block alert-danger">
								<p>#translateResource( 'cms:login.failed.error' )#</p>
							</div>
						</cfcase>
						<cfcase value="FIRST_TIME_USER_SETUP">
							<div class="alert alert-block alert-success">
								<p>#translateResource( 'cms:login.user.setup.confirmation' )#</p>
							</div>
						</cfcase>
						<cfcase value="PASSWORD_RESET">
							<div class="alert alert-block alert-success">
								<p>#translateResource( 'cms:login.password.reset.confirmation' )#</p>
							</div>
						</cfcase>
					</cfswitch>

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

								<a href="#event.buildAdminLink( linkTo='login.forgottenPassword' )#" class="pull-right">
									#translateResource( 'cms:login.forgotpw.link' )#
								</a>
							</div>
						</fieldset>
					</form>
				</div><!--/widget-main-->
			</div><!--/widget-body-->
		</div><!--/login-box-->



	</div><!--/position-relative-->
</cfoutput>