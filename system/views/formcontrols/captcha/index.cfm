<cfscript>
	siteKey   = args.siteKey ?: "";
	theme     = args.theme   ?: "light";
	size      = args.size    ?: "normal";
	tabindex  = getNextTabIndex();

	event.include( "recaptcha-js" );
</cfscript>

<cfoutput>
	<div class="g-recaptcha" data-sitekey="#siteKey#" data-theme="#theme#" data-size="#size#" data-tabindex="#getNextTabIndex()#"></div>
</cfoutput>