<cfscript>
	token         = rc.token          ?: "";
	message       = rc.message        ?: "";
	policyMessage = prc.policyMessage ?: "";

	event.include( "/js/admin/specific/passwordscore/" )
	     .include( "/css/admin/specific/passwordscore/" )
	     .includeData( { passwordScoreCheckerUrl=event.buildLink( linkTo="passwordStrengthReport.index" ) } );
</cfscript>

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
						<cfcase value="PASSWORD_NOT_STRONG_ENOUGH">
							<div class="alert alert-block alert-danger">
								<p>#translateResource( 'cms:resetLogin.password.not.strong.enough.error' )#</p>
							</div>
						</cfcase>

						<cfcase value="UNKNOWN_ERROR">
							<div class="alert alert-block alert-danger">
								<p>#translateResource( 'cms:resetLogin.unknown.error' )#</p>
							</div>
						</cfcase>
					</cfswitch>

					<div class="space-6"></div>

					<form action="#event.buildAdminLink( 'login.resetPasswordAction' )#" method="post">
						<input type="hidden" name="token" value="#token#" />
						<fieldset>
							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="password" class="form-control" placeholder="#translateResource( 'cms:resetLogin.password.placeholder' )#" name="password" data-password-policy-context="cms" autocomplete="new-password" />
									<i class="fa fa-lock"></i>
								</span>
							</label>

							<label class="block clearfix">
								<span class="block input-icon input-icon-right">
									<input type="password" class="form-control" placeholder="#translateResource( 'cms:resetLogin.password.confirmation.placeholder' )#" name="passwordConfirmation" autocomplete="new-password" />
									<i class="fa fa-lock"></i>
								</span>
							</label>

							<cfif Len( Trim( policyMessage ) )>
								<div class="alert alert-info">
									<h4><i class="fa fa-fw fa-info-circle"></i> #translateResource( "cms:passwordpolicy.title" )#</h4>

									#policyMessage#
								</div>
							</cfif>

							<div class="space-6"></div>

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