<!---@feature admin--->
<cfscript>
	infoCard        = prc.infoCard ?: "";
	topRightButtons = prc.topRightButtons ?: "";
	tabs            = prc.tabs     ?: "";
</cfscript>

<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">
			#topRightButtons#
		</div>
	</cfif>

	#infoCard#
	#tabs#
</cfoutput>