<cfset message = rc.message ?: "" />

<cfoutput>
	<div class="position-relative">
		<div id="forgot-box" class="forgot-box visible widget-box no-border">
			<div class="widget-body">
				<div class="widget-main">
					<h4 class="header red lighter bigger">
						<i class="fa fa-key"></i>
						#translateResource( 'cms:firstTimeUserSetup.title' )#<!--Retrieve Password-->
					</h4>

					<cfswitch expression="#message#">
						<cfcase value="EMPTY_PASSWORD">
							<div class="alert alert-block alert-danger">
								<p>#translateResource( 'cms:firstTimeUserSetup.empty.password.error' )#</p>
							</div>
						</cfcase>
						<cfcase value="PASSWORDS_DO_NOT_MATCH">
							<div class="alert alert-block alert-danger">
								<p>#translateResource( 'cms:firstTimeUserSetup.passwords.do.not.match.error' )#</p>
							</div>
						</cfcase>
					</cfswitch>

					<div class="space-6"></div>
					<p>
						#translateResource( 'cms:firstTimeUserSetup.prompt' )#
					</p>

					<form action="#event.buildAdminLink( 'login.firstTimeUserSetupAction' )#" method="post">
						<fieldset>
							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="email" class="form-control" placeholder="#translateResource( 'cms:firstTimeUserSetup.email_address.placeholder' )#" name="email_address" />
									<i class="fa fa-envelope"></i>
								</span>
							</label>

							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="password" class="form-control" placeholder="#translateResource( 'cms:firstTimeUserSetup.password.placeholder' )#" name="password" autocomplete="new-password" />
									<i class="fa fa-lock"></i>
								</span>
							</label>

							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="password" class="form-control" placeholder="#translateResource( 'cms:firstTimeUserSetup.password.confirmation.placeholder' )#" name="passwordConfirmation" autocomplete="new-password" />
									<i class="fa fa-lock"></i>
								</span>
							</label>

							<div class="row-fluid">
								<button class="span10 offset2 btn btn-sm btn-danger">
									<i class="fa fa-envelope-alt"></i>
									#translateResource( 'cms:firstTimeUserSetup.button' )#
								</button>
							</div>
						</fieldset>
					</form>
				</div><!--/widget-main-->
			</div><!--/widget-body-->
		</div><!--/forgot-box-->


	</div><!--/position-relative-->
</cfoutput>