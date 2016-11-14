<cfscript>
	formId           = "configure-layout";
	layoutId         = rc.layout ?: "";
	formAction       = event.buildAdminLink( linkTo='emailcenter.layouts.saveConfigurationAction' );
	layoutFormName   = prc.layoutFormName ?: "";
	savedConfig      = prc.savedConfig ?: {};
	validationResult = rc.validationResult ?: "";
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<form id="#formId#" method="post" action="#formAction#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal">
			<input type="hidden" name="layout" value="#layoutId#">


			#renderForm(
				  formName         = layoutFormName
				, context          = "admin"
				, formId           = formId
				, savedData        = savedConfig
				, validationResult = validationResult
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
	</cfsavecontent>

	#renderView( view="/admin/emailcenter/layouts/_layoutTabs", args={ body=body, tab="configure" } )#
</cfoutput>