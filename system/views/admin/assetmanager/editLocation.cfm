<cfscript>
	locationId = rc.id ?: "";
	location   = prc.location ?: {};
	formName   = prc.formName ?: "";
	formId     = "editlocation" & CreateUUId();
	formAction = event.buildAdminLink( "assetmanager.editLocationAction" );
</cfscript>

<cfoutput>
	<p class="alert alert-warning">
		<i class="fa fa-exclamation-triangle fa-fw"></i>
		#translateResource( "cms:assetmanager.location.change.warning" )#
	</p>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#formAction#">
		<input name="id" type="hidden" value="#locationId#">

		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, savedData        = location
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
					#translateResource( "cms:assetmanager.savelocation.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>