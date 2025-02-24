<!---@feature admin--->
<cfscript>
	infoCard              = prc.infoCard              ?: "";
	topRightButtons       = prc.topRightButtons       ?: "";
	tabs                  = prc.tabs                  ?: "";
	preViewRecordContent  = prc.preViewRecordContent  ?: "";
	postViewRecordContent = prc.postViewRecordContent ?: "";
</cfscript>

<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">
			#topRightButtons#
		</div>
	</cfif>

	#preViewRecordContent#
	#infoCard#
	#tabs#
	#postViewRecordContent#
</cfoutput>