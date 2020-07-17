<cfscript>
	formName   = prc.formName ?: "";
	formId     = "createscheduledreport-" & CreateUUId();
	formAction = event.buildAdminLink( "scheduledReport.createAction" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#formAction#">

		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, savedData        = ( prc.savedData       ?: {} )
			, validationResult = ( rc.validationResult ?: "" )
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( 'scheduledReport.create' )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:add.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>