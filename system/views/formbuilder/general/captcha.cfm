<cfscript>
	siteKey          = recaptchaSiteKey();
	validationResult = rc.validationResult ?: "";
	if ( !IsSimpleValue( validationResult ) && validationResult.fieldHasError( "recaptcha" ) ) {
		errorMessage = translateResource( validationResult.getError( "recaptcha" ) );
	} else {
		errorMessage = "";
	}

	recaptchaIncludeJs();
</cfscript>

<cfoutput>
	<div class="form-group">
		<div class="col-md-offset-3">
			<div class="col-md-9">
				<div class="g-recaptcha" data-sitekey="#siteKey#" data-tabindex="#getNextTabIndex()#"></div>
				<cfif Len( Trim( errorMessage ) )>
					<label class="error">#errorMessage#</label>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>