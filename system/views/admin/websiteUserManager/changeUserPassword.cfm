<cfscript>
	prc.pageIcon  = "key";
	prc.pageTitle = translateResource( uri="cms:websiteUserManager.changeUserPassword.page.title", data=[ prc.record.display_name ?: "" ] );

	user                 = prc.record ?: QueryNew('');
	formId               = "change-user-password-form";
	changePasswordAction = event.buildAdminLink( linkTo="websiteUserManager.changeUserPasswordAction" );
	cancelAction         = event.buildAdminLink( linkTo="websiteUserManager.index"                    );

	hasRightHandCol      = Len( Trim( prc.policyMessage ?: "" ) );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#changePasswordAction#">
		<input type="hidden" name="id" value="#user.id#" />

		<cfif hasRightHandCol>
			<div class="row">
				<div class="col-md-9">
		</cfif>

		#renderForm(
			  formName          = "preside-objects.website_user.admin.change.password"
			, context           = "admin"
			, formId            = formId
			, validationResult  = rc.validationResult ?: ""
		)#

		<cfif hasRightHandCol>
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
			<div class="col-md-offset-2">
				<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:datamanager.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:websiteUserManager.changepassword.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>
