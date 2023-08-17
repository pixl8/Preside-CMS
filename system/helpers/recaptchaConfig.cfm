<cffunction name="recaptchaIncludeJs" access="public" returntype="void" output="false"><cfsilent>
	<cfscript>
		getController().renderViewlet( event="admin.recaptchaConfig.includeJs" );
	</cfscript>
</cfsilent></cffunction>

<cffunction name="recaptchaValidationEndpoint" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getController().renderViewlet( event="admin.recaptchaConfig.validationEndpoint" )>
</cfsilent></cffunction>

<cffunction name="recaptchaSiteKey" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getController().renderViewlet( event="admin.recaptchaConfig.siteKey" )>
</cfsilent></cffunction>

<cffunction name="recaptchaSecretKey" access="public" returntype="string" output="false"><cfsilent>
	<cfreturn getController().renderViewlet( event="admin.recaptchaConfig.secretKey" )>
</cfsilent></cffunction>