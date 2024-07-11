<!---@feature admin--->
<cfscript>
	postLoginUrl           = args.postLoginUrl ?: "";
	message                = rc.message ?: "";
	isRememberMeEnabled    = IsTrue( args.isRememberMeEnabled ?: "" );
	rememberMeExpiryInDays = Val( args.rememberMeExpiryInDays ?: 30 );
	loginProviderPosition  = Val( args.position ?: "" );

	if ( rememberMeExpiryInDays == 1 ) {
		rememberMeLabel = translateResource( uri="cms:login.remember.me.single.day.label" );
	} else {
		rememberMeLabel = translateResource( uri="cms:login.remember.me.label", data=[ rememberMeExpiryInDays ] );
	}
</cfscript>
<cfoutput>
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

	<cfif !Len( Trim( message ) ) && loginProviderPosition gt 1>
		<p class="text-center">
			<a href="##preside-standard-login" data-toggle="collapse">
				<i class="fa fa-fw fa-caret-right"></i>
				<em>#translateResource( "cms:login.standard.login.toggle.title" )#</em>
			</a>
		</p>
		<div id="preside-standard-login" class="collapse">
	</cfif>
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
					<input type="password" class="form-control" placeholder="#translateResource( 'cms:login.password.placeholder' )#" name="password" id="password" />

					<cfif isFeatureEnabled( "passwordVisibilityToggle" )>
						<i data-target="##password" class="fa fa-eye toggle-password"></i>
					<cfelse>
						<i class="fa fa-lock"></i>
					</cfif>
				</span>
			</label>

			<cfif isRememberMeEnabled>
				<div class="checkbox clearfix">
					<label class="block">
						<span class="block">
							<input type="checkbox" name="rememberme" value="true" />
							#rememberMeLabel#
						</span>
					</label>
				</div>
			</cfif>

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

	<cfif !Len( Trim( message ) ) && loginProviderPosition gt 1>
		</div>
	</cfif>
</cfoutput>