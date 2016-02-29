<cfscript>
	siteKey = getSystemSetting( 'formbuilder', 'recaptcha_site_key' );
	event.include( "recaptcha-js" );
</cfscript>

<cfoutput>
	<div class="form-group">
		<div class="col-md-offset-2">
			<div class="col-md-9">
				<div class="g-recaptcha" data-sitekey="#siteKey#" data-tabindex="#getNextTabIndex()#"></div>
			</div>
		</div>
	</div>
</cfoutput>