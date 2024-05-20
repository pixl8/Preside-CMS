<!---@feature admin and customEmailTemplates--->
<cfscript>
	templateId   = rc.id            ?: "";
	filterObject = prc.filterObject ?: "";
	gridFields   = prc.gridFields   ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = filterObject
		, useMultiActions = false
		, datasourceUrl   = event.buildAdminLink( linkTo="emailCenter.customTemplates.getRecipientListForAjaxDataTables", queryString="id=" & templateId  & "&addPreviewLink=true&hideAlreadySent=false")
		, gridFields      = gridFields
		, draftsEnabled   = false
		, allowSearch     = true
		, allowFilter     = true
		, allowDataExport = false
	} )#
</cfoutput>