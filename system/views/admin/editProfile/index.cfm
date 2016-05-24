<cfscript>
	formId = "edit-profile-form-" & CreateUUId();
</cfscript>


<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#event.buildAdminLink( linkTo="editProfile.editProfileAction" )#">
		#renderForm(
			  formName          = "preside-objects.security_user.admin.edit.profile"
			, context           = "admin"
			, formId            = formId
			, savedData         = prc.record ?: {}
			, validationResult  = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo='' )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:save.btn" )#
				</button>
			</div>
		</div>
	</form>

</cfoutput>