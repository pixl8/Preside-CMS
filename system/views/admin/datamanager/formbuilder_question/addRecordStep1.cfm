<cfscript>
	addRecordLink = prc.addRecordLink ?: "";
	cancelLink    = prc.cancelLink ?: "";
	formName      = prc.formName ?: "";
	formId        = "addformbuilderquestionstep1";
</cfscript>

<cfoutput>
	<p class="alert alert-info">
		<i class="fa fa-fw fa-info-circle"></i>
		#translateResource( "preside-objects.formbuilder_question:add.question.step1.intro" )#
	</p>

	<form class="form form-horizontal" action="#addRecordLink#" method="POST" id="#formId#">
		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, validationResult = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelLink#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-fw fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button type="submit" class="btn btn-success" tabindex="1">
					<i class="fa fa-fw fa-angle-double-right bigger-110"></i>

					#translateResource( "cms:next.with.ellipses.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>