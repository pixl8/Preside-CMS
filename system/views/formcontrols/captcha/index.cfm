<cfscript>
	siteKey  = args.siteKey ?: "";
	theme    = args.theme   ?: "light";
	size     = args.size    ?: "normal";
	tabindex = getNextTabIndex();

	event.include( "recaptcha-js" );

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<div class="g-recaptcha" data-sitekey="#siteKey#" data-theme="#theme#" data-size="#size#" data-tabindex="#getNextTabIndex()#" #htmlAttributes#></div>
</cfoutput>
