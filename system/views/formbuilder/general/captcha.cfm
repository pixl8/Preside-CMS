<cfscript>
	siteKey          = getSystemSetting( 'recaptcha', 'site_key' );
	validationResult = rc.validationResult ?: "";
	if ( !IsSimpleValue( validationResult ) && validationResult.fieldHasError( "recaptcha" ) ) {
		errorMessage = translateResource( validationResult.getError( "recaptcha" ) );
	} else {
		errorMessage = "";
	}

	event.include( "recaptcha-js" );
</cfscript>

<cfoutput>
	<div class="form-group">
		<div class="col-md-offset-2">
			<div class="col-md-9">
				<div class="g-recaptcha" data-sitekey="#siteKey#" data-tabindex="#getNextTabIndex()#"></div>
				<cfif Len( Trim( errorMessage ) )>
					<label class="error">#errorMessage#</label>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>