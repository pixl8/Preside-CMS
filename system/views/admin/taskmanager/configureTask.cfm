<cfscript>
	formId = "taskmanager-configuration";
</cfscript>

<cfoutput>
	<form id="#formId#" method="post" action="#event.buildAdminLink( linkTo='taskmanager.saveTaskConfigurationAction' )#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal">
		<input name="task" type="hidden" value="#( rc.task ?: '' )#">

		#renderForm(
			  formName          = "taskmanager.task_configuration"
			, context           = "admin"
			, formId            = formId
			, savedData         = prc.taskConfiguration ?: {}
			, validationResult  = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:save.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>