<cfscript>
	objectName    = args.objectName     ?: "formbuilder_question";
	propertyName  = args.propertyName   ?: "forms";
	recordId      = args.recordId       ?: "";
	queryString   = "objectName=#objectName#&propertyName=#propertyName#&recordId=#args.recordId#";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName        = "formbuilder_form"
		, gridFields        = [ "name" ]
		, dataSourceUrl     = event.buildAdminLink( linkto="datamanager.formbuilder_question.getRelatedFormRecordsForAjaxDatatable", queryString=queryString )
		, compact           = true
		, useMultiActions   = false
		, isMultilingual    = false
		, draftsEnabled     = false
		, allowSearch       = true
		, allowFilter       = false
		, allowDataExport   = false
		, noRecordMessage   = translateResource( uri="preside-objects.formbuilder_question:viewgroup.forms.datatables.emptyTable" )
	} )#
</cfoutput>
