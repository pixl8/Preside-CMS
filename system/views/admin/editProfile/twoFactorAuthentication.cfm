<cfscript>
	enforced = IsTrue( prc.enforced ?: "" );
	enabled  = IsTrue( prc.enabled  ?: "" );
	doSetup  = IsTrue( prc.doSetup  ?: "" );

	authKey  = prc.authenticationKey ?: "";
	qrCode   = prc.qrCode            ?: "";
</cfscript>

<cfoutput>
	<cfif enforced>
		<p class="alert alert-success">
			<i class="fa fa-fw fa-check green"></i>&nbsp;
			#translateResource( "cms:editProfile.twofactorauthentication.enabled.message" )#
		</p>

		<div class="form-actions row">
			<a href="#event.buildAdminLink( linkTo='editProfile.disableTwoFactorAuthenticationAction', queryString='reset=true' )#" class="btn btn-info confirmation-prompt" title="#HtmlEditFormat( translateResource( "cms:editProfile.twofactorauthentication.reset.enforced.prompt" ) )#">
				<i class="fa fa-refresh bigger-110"></i>
				#translateResource( "cms:editProfile.twofactorauthentication.reset.enforced.btn" )#
			</a>
		</div>
	<cfelse>
		<cfif enabled>
			<p class="alert alert-success">
				<i class="fa fa-fw fa-check green"></i>&nbsp;
				#translateResource( "cms:editProfile.twofactorauthentication.enabled.message" )#
			</p>

			<div class="form-actions row">
				<a href="#event.buildAdminLink( linkTo='editProfile.disableTwoFactorAuthenticationAction' )#" class="btn btn-danger confirmation-prompt" title="#HtmlEditFormat( translateResource( "cms:editProfile.twofactorauthentication.disable.prompt" ) )#">
					<i class="fa fa-ban bigger-110"></i>
					#translateResource( "cms:editProfile.twofactorauthentication.disable.btn" )#
				</a>

				<a href="#event.buildAdminLink( linkTo='editProfile.disableTwoFactorAuthenticationAction', queryString='reset=true' )#" class="btn btn-info confirmation-prompt" title="#HtmlEditFormat( translateResource( "cms:editProfile.twofactorauthentication.reset.prompt" ) )#">
					<i class="fa fa-refresh bigger-110"></i>
					#translateResource( "cms:editProfile.twofactorauthentication.reset.btn" )#
				</a>
			</div>

		<cfelse>
			<cfif doSetup>
				<p class="alert alert-info">#translateResource( "cms:editProfile.twofactorauthentication.setup.introduction" )#</p>

				<div class="row">
					<div class="col-md-3">
						<div class="text-center well">
							<img src="data:image/gif;base64,#qrCode#" /><br><br>
							<p>#translateResource( uri="cms:editProfile.twofactorauthentication.qrcode.instruction", data=[ '<a href="##two-factor-private-key" data-toggle="collapse">#translateResource( 'cms:editProfile.twoFactorAuthentication.show.key.link')#</a>'] )#</p>

							<p id="two-factor-private-key" class="alert alert-warning collapse">#authKey#</p>
						</div>
					</div>
					<div class="col-md-9 col-lg-6">
						<h3 class="blue title">#translateResource( "cms:editProfile.twofactorauthentication.setup.instructions.title" )#</h3>
						<br>
						<ol class="list-extra-line-height">
							<li>#translateResource( "cms:editProfile.twofactorauthentication.setup.instructions.step1" )#</li>
							<li>#translateResource( "cms:editProfile.twofactorauthentication.setup.instructions.step2" )#</li>
							<li>#translateResource( "cms:editProfile.twofactorauthentication.setup.instructions.step3" )#</li>
						</ol>
						<hr>

						<form method="post" action="#event.buildAdminLink( 'editProfile.completeTwoFactorAuthSetupAction' )#" class="form-horizontal" id="confirm-two-factor-auth">
							#renderForm(
								  formName         = "two-factor-auth.confirm.setup"
								, context          = "admin"
								, formId           = "confirm-two-factor-auth"
								, validationResult = ( rc.validationResult ?: "" )
							)#

							<div class="col-md-offset-2">
								<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
									<i class="fa fa-check bigger-110"></i>
									#translateResource( "cms:editProfile.twofactorauthentication.complete.setup.btn" )#
								</button>
							</div>
						</form>
					</div>
				</div>

			<cfelse>
				<div class="alert alert-warning">
					<p>
						<i class="fa fa-fw fa-exclamation-circle"></i>
						#translateResource( "cms:editProfile.twofactorauthentication.not.enabled.description" )#
					</p>
					<br>
					<a class="btn btn-success" href="#event.buildAdminLink( linkTo='editProfile.twoFactorAuthentication', queryString='setup=true' )#">
						<i class="fa fa-fw fa-magic"></i> #translateResource( "cms:editProfile.twofactorauthentication.get.started.btn" )#
					</a>
				</div>
			</cfif>
		</cfif>

	</cfif>
</cfoutput>