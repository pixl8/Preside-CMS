<cfscript>
	provider   = rc.provider  ?: "filesystem";
	formName   = prc.formName ?: "";
	formId     = "addlocation" & CreateUUId();
	formAction = event.buildAdminLink( "assetmanager.addLocationAction" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#formAction#">
		<input type="hidden" name="provider" value="#provider#">

		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, validationResult = ( rc.validationResult ?: "" )
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( 'assetmanager.managelocations' )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:assetmanager.addlocation.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>