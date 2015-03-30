<cfscript>
	formId        = "maintenance-mode-settings";
	savedSettings = prc.settings ?: {};
</cfscript>

<cfoutput>
	<div class="alert alert-info">
		<i class="fa fa-fw fa-info-circle"></i>
		#translateResource( "cms:maintenanceMode.introduction" )#
	</div>

	<form id="#formId#" action="#event.buildAdminLink( linkTo='maintenanceMode.saveSettingsAction' )#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post">
		#renderForm(
			  formName          = "maintenance-mode.settings"
			, context           = "admin"
			, formId            = formId
			, savedData         = savedSettings
			, validationResult  = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( 'cms:save.btn' )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>