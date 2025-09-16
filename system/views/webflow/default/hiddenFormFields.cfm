<!---@feature webflow--->
<cfscript>
	obfuscatedFields = args.obfuscatedFields ?: "";
	returnUrl        = args.returnUrl        ?: "";
	webflowArgs      = args.webflowArgs      ?: {};
	isLazyLoaded     = IsTrue( args.isLazyLoaded ?: "" );
</cfscript>

<cfoutput>
	<input type="hidden" name="_wid"      value="#obfuscatedFields#">
	<input type="hidden" name="_rurl"     value="#returnUrl#">
	<cfif !isLazyLoaded>
		<input type="hidden" name="csrfToken" value="#event.getCsrfToken()#">
	</cfif>
	<cfloop collection="#webflowArgs#" item="argValue" index="argName">
		<cfif IsSimpleValue( argValue ) && Len( Trim( argValue ) )>
			<input type="hidden" name="args.#argName#" value="#HtmlEditFormat( argValue )#" />
		</cfif>
	</cfloop>
</cfoutput>