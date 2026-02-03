<!---@feature presideForms--->
<cfscript>
	siteKey  = args.siteKey ?: "";
	theme    = args.theme   ?: "light";
	size     = args.size    ?: "normal";
	tabindex = getNextTabIndex();

	event.include( "recaptcha-js" );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<div class="g-recaptcha" data-sitekey="#siteKey#" data-theme="#theme#" data-size="#size#" data-tabindex="#getNextTabIndex()#" #htmlAttributes#></div>
</cfoutput>
