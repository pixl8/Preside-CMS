<cfscript>
	postLoginUrl      = event.getValue( name="postLoginUrl", defaultValue=event.buildAdminLink( linkto=getSetting( "adminDefaultEvent" ) ) );
	message           = rc.message ?: "";
	twoFactorSetup    = IsTrue( prc.twoFactorSetup ?: "" );
	authenticationKey = prc.authenticationKey ?: "";
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
						<div class="col-md-6">
							<div class="login-help-box right-col">
								<cfif twoFactorSetup>
									<h4 class="login-help-title grey">#translateResource( 'cms:login.two.factor.auth.help.title' )#</h4>
									<p class="grey">#translateResource( 'cms:login.two.factor.auth.help.first.para' )#</p>

									<img class="login-help-image" src="#event.buildLink( systemStaticAsset='/images/furniture/two-factor-icons.png' )#">

									<p class="grey">#translateResource( 'cms:login.two.factor.auth.help.gethelp.para' )#</p>
								<cfelse>
									<h4 class="login-help-title grey">#translateResource( 'cms:login.two.factor.auth.setup.title' )#</h4>
									<p class="grey">#translateResource( 'cms:login.two.factor.auth.setup.first.para' )#</p>

									<p class="alert alert-warning center">#authenticationKey#</p>

									<p class="grey">#translateResource( 'cms:login.two.factor.auth.setup.second.para' )#</p>
								</cfif>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>