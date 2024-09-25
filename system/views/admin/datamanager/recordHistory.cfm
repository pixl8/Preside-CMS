<!---@feature admin--->
<cfoutput>#outputView(
	  view = "/admin/datamanager/_objectVersionHistoryTable"
	, args = { objectName=prc.objectName ?: "" }
)#</cfoutput>