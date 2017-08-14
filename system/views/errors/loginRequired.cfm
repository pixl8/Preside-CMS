<!---
	This 'login required' view which is rendered by the errors.accessDenied handler, is just a proxy to the 'login.loginPage' viewlet.
	This seems absurd; however, this promotes maximum re-use and extensibility
 --->
 <cfscript>
	args         = args ?: {};
	args.message = "LOGIN_REQUIRED";
</cfscript>
<cfoutput>#renderViewlet( event="login.loginPage", args=args )#</cfoutput>