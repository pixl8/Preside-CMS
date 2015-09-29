<cfscript>
	hasRightCol = Len( Trim( prc.policyMessage ?: "" ) );
	formId      = "edit-profile-form-" & CreateUUId();
</cfscript>


<cfoutput>
	<p>#translateResource( "cms:editProfile.introduction")#</p><br>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#event.buildAdminLink( linkTo="editProfile.editProfileAction" )#">

		<cfif hasRightCol>
			<div class="row">
				<div class="col-md-9">
		</cfif>

		#renderForm(
			  formName          = "preside-objects.security_user.admin.edit.profile"
			, context           = "admin"
			, formId            = formId
			, savedData         = prc.record ?: {}
			, validationResult  = rc.validationResult ?: ""
		)#

		<cfif hasRightCol>
				</div>

				<div class="col-md-3">
					<div class="alert alert-info">
						<h4><i class="fa fa-fw fa-info-circle"></i> #translateResource( "cms:passwordpolicy.title" )#</h4>

						#prc.policyMessage#
					</div>
				</div>
			</div>
		</cfif>

		<div class="form-actions row">
			<cfif hasRightCol>
				<div class="row">
					<div class="col-md-9">
			</cfif>
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
			<cfif hasRightCol>
				</div></div>
			</cfif>
		</div>
	</form>

</cfoutput>