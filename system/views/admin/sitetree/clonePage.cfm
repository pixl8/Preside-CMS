<!---@feature admin and sitetree--->
<cfscript>
	pageId           = rc.id               ?: "";
	page             = prc.page            ?: QueryNew('');
	mainFormName     = prc.mainFormName    ?: "";
	mergeFormName    = prc.mergeFormName   ?: "";
	validationResult = rc.validationResult ?: "";
	formId           = "cloneForm-" & CreateUUId();
	formAction       = event.buildAdminLink( linkTo='sitetree.clonePageAction' );

	canPublish   = IsTrue( prc.canPublish   ?: "" );
	canSaveDraft = IsTrue( prc.canSaveDraft ?: "" );
</cfscript>

<cfoutput>
	<p class="alert alert-info">
		<i class="fa fa-fw fa-info-circle"></i>
		#translateResource( "cms:sitetree.clonePage.intro" )#
	</p>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#formAction#">
		<input type="hidden" name="id" value="#pageId#" />

		#renderForm(
			  formName                = mainFormName
			, mergeWithFormName       = mergeFormName
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
				<a href="#event.buildAdminLink( linkTo="sitetree" )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<button type="submit" class="btn btn-info" tabindex="#getNextTabIndex()#">
					<i class="fa fa-clone bigger-110"></i> #translateResource( "cms:sitetree.clonePage.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>