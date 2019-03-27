<cfscript>
	topRightButtons = prc.topRightButtons ?: "";
	addRecordForm   = prc.addRecordForm   ?: "";
</cfscript>

<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	#addRecordForm#
</cfoutput>