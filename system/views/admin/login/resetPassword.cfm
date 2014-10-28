<cfset token   = rc.token ?: "" />
<cfset message = rc.message ?: "" />

<cfoutput>
	<div class="position-relative">
		<div id="forgot-box" class="forgot-box visible widget-box no-border">
			<div class="widget-body">
				<div class="widget-main">
					<h4 class="header red lighter bigger">
						<i class="fa fa-key"></i>
						#translateResource( 'cms:resetLogin.title' )#
					</h4>

					<cfswitch expression="#message#">
						<cfcase value="EMPTY_PASSWORD">
							<div class="alert alert-block alert-danger">
								<p>#translateResource( 'cms:resetLogin.empty.password.error' )#</p>
							</div>
						</cfcase>
						<cfcase value="PASSWORDS_DO_NOT_MATCH">
							<div class="alert alert-block alert-danger">
								<p>#translateResource( 'cms:resetLogin.passwords.do.not.match.error' )#</p>
							</div>
						</cfcase>
						<cfcase value="UNKNOWN_ERROR">
							<div class="alert alert-block alert-danger">
								<p>#translateResource( 'cms:resetLogin.unknown.error' )#</p>
							</div>
						</cfcase>
					</cfswitch>

					<div class="space-6"></div>
					<p>
						#translateResource( 'cms:resetLogin.prompt' )#
					</p>

					<form action="#event.buildAdminLink( 'login.resetPasswordAction' )#" method="post">
						<input type="hidden" name="token" value="#token#" />
						<fieldset>
							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="password" class="form-control" placeholder="#translateResource( 'cms:resetLogin.password.placeholder' )#" name="password" />
									<i class="fa fa-lock"></i>
								</span>
							</label>

							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="password" class="form-control" placeholder="#translateResource( 'cms:resetLogin.password.confirmation.placeholder' )#" name="passwordConfirmation" />
									<i class="fa fa-lock"></i>
								</span>
							</label>

							<div class="row-fluid">
								<button class="span10 offset2 btn btn-sm btn-danger">
									<i class="fa fa-envelope-alt"></i>
									#translateResource( 'cms:resetLogin.button' )#
								</button>

								<a href="#event.buildAdminLink( linkTo='login' )#" class="pull-right">
									#translateResource( 'cms:resetLogin.login.link' )#
								</a>
							</div>
						</fieldset>
					</form>
				</div><!--/widget-main-->
			</div><!--/widget-body-->
		</div><!--/forgot-box-->


	</div><!--/position-relative-->
</cfoutput>