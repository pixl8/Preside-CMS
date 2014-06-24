<cfscript>
	param name="prc.category"  type="ConfigCategory";
	param name="prc.savedData" type="struct";

	formId = "edit-system-config-" & ( rc.id ?: "" );
</cfscript>

<cfoutput>
	<form id="#formId#" method="post" action="#event.buildAdminLink( linkTo='sysConfig.saveCategoryAction' )#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal">
		<input type="hidden" name="id" value="#( rc.id ?: '' )#">

		#renderForm(
			  formName          = prc.category.getForm()
			, context           = "admin"
			, formId            = formId
			, savedData         = prc.savedData
			, validationResult  = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:sysConfig.save.button" )#
				</button>
			</div>
		</div>
	</form>

</cfoutput>