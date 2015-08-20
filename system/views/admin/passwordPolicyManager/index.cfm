<cfscript>
	formId  = "password-policy-form";

	policyContexts = prc.policyContexts ?: [];
	currentContext = prc.currentContext ?: "cms";
	savedPolicy    = prc.savedPolicy    ?: {};
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<cfloop array="#policyContexts#" index="policyContext">
				<cfset active = ( policyContext == currentContext ) />

				<li<cfif active> class="active"</cfif>>
					<a href="#event.buildAdminLink( linkTo='passwordPolicyManager', queryString='context=' & policyContext )#">
						#translateResource( "cms:passwordpolicycontext.#policyContext#.title" )#
					</a>
				</li>
			</cfloop>
		</ul>

		<div class="tab-content">

			<form data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" id="#formId#" action="#event.buildAdminLink( linkTo='passwordPolicyManager.editPolicyAction' )#" method="post">
				<input type="hidden" name="context" value="#currentContext#">

				#renderForm(
					  formName          = "preside-objects.password_policy.admin.edit"
					, context           = "admin"
					, formId            = formId
					, savedData         = savedPolicy
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
		</div>
	</div>
</cfoutput>