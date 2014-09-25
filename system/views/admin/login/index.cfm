<cfscript>
	postLoginUrl = event.getValue( name="postLoginUrl", defaultValue=event.buildAdminLink( linkto=getSetting( "adminDefaultEvent" ) ) );
</cfscript>

<cfoutput>
	<div class="position-relative">
		<div id="login-box" class="login-box visible widget-box no-border">
			<div class="widget-body">
				<div class="widget-main">
 					<h4 class="cms-brand">
						#translateResource( uri="cms:cms.title" )#
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