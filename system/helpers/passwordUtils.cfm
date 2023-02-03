<cffunction name="renderPasswordPolicyMessage" access="public" returntype="string" output="false">
	<cfargument name="context" type="string" required="true" />

	<cfreturn getController().renderViewlet( event="PasswordStrengthReport.renderPolicyMessage", args=arguments ) />
</cffunction>