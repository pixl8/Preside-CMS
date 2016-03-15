<cfscript>
	postLoginUrl      = event.getValue( name="postLoginUrl", defaultValue=event.buildAdminLink( linkto=getSetting( "adminDefaultEvent" ) ) );
	message           = rc.message ?: "";
	twoFactorSetup    = IsTrue( prc.twoFactorSetup ?: "" );
	authenticationKey = prc.authenticationKey ?: "";
	qrCode            = prc.qrCode ?: "";
</cfscript>

<cfoutput>
	<div class="position-relative">
		<div id="login-box" class="login-box visible widget-box no-border col-one">

			<div class="widget-body">
				<div class="widget-main">
					<div class="row">
						<div class="col-md-6">
							<div class="left-col">
								<h4 class="cms-brand pulled-left">
									#translateResource( uri="cms:cms.title" )#
								</h4>

								<cfswitch expression="#message#">
									<cfcase value="AUTH_FAILED">
										<div class="alert alert-block alert-danger">
											<p>#translateResource( 'cms:login.two.factor.auth.failed.error' )#</p>
										</div>
									</cfcase>
									<cfdefaultcase>
										<div class="alert alert-block alert-info">
											<p>
												#translateResource( 'cms:login.two.factor.auth.info' )#
											</p>
										</div>
									</cfdefaultcase>
								</cfswitch>

								<div class="space-6"></div>

								<form method="post" action="#event.buildAdminLink( linkto="login.twoStepAuthenticateAction" )#" data-auto-focus-form="true">
									<fieldset>
										<input type="hidden" name="postLoginUrl" value="#postLoginUrl#" />

										<label class="block clearfix">
											<span class="block input-icon input-icon-right">
												<input type="text" class="form-control" placeholder="#translateResource( 'cms:login.two.factor.auth.token.placeholder' )#" name="oneTimeToken" autocomplete="off" />
												<i class="fa fa-lock"></i>
											</span>
										</label>

										<div class="space"></div>

										<div class="row-fluid">
											<button class="span4 btn btn-sm btn-primary">
												<i class="fa fa-key"></i>
												#translateResource( 'cms:two.factor.auth.verify.button' )#
											</button>
										</div>
									</fieldset>
								</form>
							</div>
						</div>
						<div class="col-md-6 right-col">
							<div class="login-help-box">
								<cfif twoFactorSetup>
									<h4 class="login-help-title grey">#translateResource( 'cms:login.two.factor.auth.help.title' )#</h4>
									<p class="grey">#translateResource( 'cms:login.two.factor.auth.help.first.para' )#</p>

									<img class="login-help-image" src="#event.buildLink( systemStaticAsset='/images/furniture/two-factor-icons.png' )#">

									<p class="grey">#translateResource( 'cms:login.two.factor.auth.help.gethelp.para' )#</p>
								<cfelse>
									<div class="text-center">
										<img src="data:image/gif;base64,#qrCode#">
									</div>

									<p>#translateResource( uri="cms:editProfile.twofactorauthentication.qrcode.instruction", data=[ '<a href="##two-factor-private-key" data-toggle="collapse">#translateResource( 'cms:editProfile.twoFactorAuthentication.show.key.link')#</a>'] )#</p>

									<p id="two-factor-private-key" class="alert alert-warning collapse text-center">#authenticationKey#</p>

									<p>
										<a href="##more-help" data-toggle="collapse">
											<i class="fa fa-fw fa-caret-right"></i>
											#translateResource( "cms:login.two.factor.auth.setup.read.more" )#
										</a>
									</p>
									<div class="collapse" id="more-help">
										<ol class="list-extra-line-height">
											<li>#translateResource( "cms:editProfile.twofactorauthentication.setup.instructions.step1" )#</li>
											<li>#translateResource( "cms:editProfile.twofactorauthentication.setup.instructions.step2" )#</li>
											<li>#translateResource( "cms:editProfile.twofactorauthentication.setup.instructions.step3" )#</li>
										</ol>

									</div>
								</cfif>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>