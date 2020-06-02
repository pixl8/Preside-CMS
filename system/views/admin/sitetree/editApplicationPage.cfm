<cfscript>
	pageId           = rc.id ?: "";
	validationResult = rc.validationResult ?: "";
	configFormName   = prc.configFormName ?: "";
	pageConfig       = prc.pageConfig     ?: {};

	formId = "application-page-config-form-" & pageId;
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='sitetree.editApplicationPageAction' )#">
		<input type="hidden" name="id" value="#pageId#" />

		#renderForm(
			  formName                = configFormName
			, context                 = "admin"
			, formId                  = formId
			, savedData               = pageConfig
			, validationResult        = validationResult
			, stripPermissionedFields = true
			, permissionContext       = "page"
			, permissionContextKeys   = ( prc.pagePermissionContext ?: [] )
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo="sitetree" )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:sitetree.savepage.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>