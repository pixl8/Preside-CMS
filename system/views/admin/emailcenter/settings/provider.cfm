<cfscript>
	providerId = rc.id ?: "";
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.emailcenter.settings._generalSettingsTabs", args={ body="", tab=providerId } )#
</cfoutput>