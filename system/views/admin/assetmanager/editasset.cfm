<cfscript>
	assetId = rc.asset  ?: "";
	asset   = prc.asset ?: QueryNew('');

	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.edit.asset.title" );

	event.addAdminBreadCrumb(
		  title = translateResource( "cms:assetmanager.edit.asset.title" )
		, link  = event.buildAdminLink( linkTo="assetmanager.editAsset", queryString="asset=#assetId#" )
	);

	saveBtnTitle = translateResource( "cms:assetManager.add.asset.form.save.button" );
	cancelBtnTitle = translateResource( "cms:assetManager.add.asset.form.cancel.button" );
</cfscript>

<cfoutput>
	<form id="edit-asset-form" class="form-horizontal edit-asset-form" data-auto-focus-form="true" data-dirty-form="protect" action="#event.buildAdminLink( linkto="assetmanager.editAssetAction" )#" method="post">
		<input type="hidden" name="asset" value="#( rc.asset ?: "" )#" />

		<div class="well">
			<div class="row">
				<div class="col-sm-2">
					#renderAsset( assetId=assetId, context="adminPreview" )#
				</div>

				<div class="col-sm-10">

 					#renderForm(
						  formName         = "preside-objects.asset.admin.edit"
						, formId           = "edit-asset-form"
						, context          = "admin"
						, savedData        = queryRowToStruct( asset )
						, validationResult = rc.validationResult ?: ""
					)#

					<div class="col-md-offset-2">
						<a href="#event.buildAdminLink( linkTo="assetmanager", queryString="folder=#asset.asset_folder#" )#" class="btn cancel-asset-btn"><i class="fa fa-remove-sign"></i> #cancelBtnTitle#</a>
						<button type="input" class="btn btn-primary"><i class="fa fa-check"></i> #saveBtnTitle#</button>
					</div>
				</div>
			</div>
		</div>
	</form>
</cfoutput>