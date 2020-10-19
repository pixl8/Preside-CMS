<cfscript>
	leftCol                  = args.leftCol                  ?: "";
	rightCol                 = args.rightCol                 ?: "";
	answerDatatable          = args.answerDatatable          ?: "";
	preRenderRecord          = args.preRenderRecord          ?: "";
	preRenderRecordLeftCol   = args.preRenderRecordLeftCol   ?: "";
	preRenderRecordRightCol  = args.preRenderRecordRightCol  ?: "";
	postRenderRecordLeftCol  = args.postRenderRecordLeftCol  ?: "";
	postRenderRecordRightCol = args.postRenderRecordRightCol ?: "";
	postRenderRecord         = args.postRenderRecord         ?: "";

	questionId           = prc.recordId                  ?: "";
</cfscript>

<cfoutput>

	#preRenderRecord#

	<div class="row">
		<div class="col-md-6">
			#preRenderRecordLeftCol#
			#leftCol#
			#postRenderRecordLeftCol#
		</div>
		<div class="col-md-6">
			#preRenderRecordRightCol#
			#rightCol#
			#postRenderRecordRightCol#
		</div>
	</div>

	<div class="row">
		<div class="col-md-12">
			#renderView( view="/admin/datamanager/_objectDataTable", args={
				  objectName          = "formbuilder_question_response"
				, gridFields          = [ "response","submitted_by", "is_website_user", "is_admin_user", "form_name", "datecreated" ]
				, datasourceUrl       = event.buildAdminLink( linkTo="formbuilder.listQuestionResponsesForAjaxDataTables", querystring="questionId=#questionId#" )
				, useMultiActions     = false
				, multiActionUrl      = event.buildAdminLink( "formbuilder.multiRecordAction" )
				, allowDataExport     = true
				, dataExportUrl       = event.buildAdminLink( linkto='formbuilder.exportQuestionResponses', queryString='questionid=#questionId#' )
				, dataExportConfigUrl = event.buildAdminLink( linkto='formbuilder.exportQuestionResponsesConfig', queryString='questionid=#questionId#'  )
			} )#
		</div>
	</div>

	#postRenderRecord#
</cfoutput>
