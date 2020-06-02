<cfscript>
	page             = event.getValue( name="page", defaultValue=QueryNew(''), private=true );
	validationResult = event.getValue( name="validationResult", defaultValue="" );
	formId           = "restoreForm-" & CreateUUId();

	prc.pageIcon     = "pencil";
	prc.pageTitle    = translateResource( uri="cms:sitetree.restorePage.title", data=[ prc.page.title ] );

	page.parent_page = "";
	if ( Len( Trim( page.old_slug ) ) ) {
		page.slug = page.old_slug;
	}
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#event.buildAdminLink( linkTo='sitetree.restorePageAction' )#">
		<input type="hidden" name="id" value="#event.getValue( name='id', defaultValue='' )#" />

		#renderForm(
			  formName                = "preside-objects.page.restore"
			, context                 = "admin"
			, formId                  = formId
			, savedData               = page
			, validationResult        = validationResult
			, stripPermissionedFields = true
			, permissionContext       = "page"
			, permissionContextKeys   = ( prc.pagePermissionContext ?: [] )
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:sitetree.restorepage.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>