<cfscript>
	topRightButtons = prc.topRightButtons ?: "";
</cfscript>
<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	#objectDataTable( objectName="rules_engine_condition", args={
		  allowManageFilter = false // inception!
		, gridFields        = [ "condition_name", "is_favourite", "filter_folder", "filter_sharing_scope", "owner", "datemodified" ]
		, canDelete         = false
	} )#
</cfoutput>