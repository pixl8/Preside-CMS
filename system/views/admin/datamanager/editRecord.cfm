<cfscript>
	topRightButtons  = prc.topRightButtons  ?: "";
	editRecordForm   = prc.editRecordForm   ?: "";
	versionNavigator = prc.versionNavigator ?: "";
</cfscript>

<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	#versionNavigator#

	#editRecordForm#
</cfoutput>