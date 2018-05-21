<cfoutput>#renderView(
	  view = "/admin/datamanager/_objectVersionHistoryTable"
	, args = { objectName=prc.objectName ?: "" }
)#</cfoutput>