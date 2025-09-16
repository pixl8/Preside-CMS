<!---@feature datamanagerWorkflow--->
<cfscript>
	actionUrl         = prc.actionUrl ?: "";
	cancelLink        = prc.cancelLink ?: "";
	formName          = prc.formName ?: "";
	submitButtonLabel = prc.submitButtonLabel ?: "";
	formId            = "workflow-step-form";
</cfscript>
<cfoutput>
	<form id="#formId#" action="#actionUrl#" enctype="multipart/form-data" class="form form-horizontal" method="post">
		#renderForm(
			  formName                = formName
			, context                 = "admin"
			, formId                  = formId
			, validationResult        = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelLink#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit">
					<i class="fa fa-check bigger-110"></i>
					#submitButtonLabel#
				</button>
			</div>
		</div>
	</form>
</cfoutput>