<cfscript>
	topRightButtons = prc.topRightButtons ?: "";
	renderedRecord  = prc.renderedRecord  ?: "";
	versionNavigator = prc.versionNavigator ?: "";
</cfscript>


<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	#versionNavigator#

	#renderedRecord#
</cfoutput>