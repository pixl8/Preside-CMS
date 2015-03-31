<cfscript>
	assetId = rc.asset  ?: "";
	asset   = prc.asset ?: StructNew();

	prc.pageIcon     = "picture-o";
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
	<div class="top-right-button-group">

		<a class="pull-right inline confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashAssetAction", queryString="asset=#assetId#")#" data-global-key="d" title="#HtmlEditFormat( translateResource( uri="cms:assetmanager.trash.asset.link", data=[ asset.title ] ) )#">
			<button class="btn btn-danger btn-sm">
				<i class="fa fa-trash-o"></i>
				#translateResource( uri="cms:assetmanager.delete.btn" )#
			</button>
		</a>

		<a class="pull-right inline" href="#event.buildLink( assetId=assetId )#" data-global-key="w" title="#HtmlEditFormat( translateResource( uri="cms:assetmanager.download.asset.link", data=[ asset.title ] ) )#" target="_blank">
			<button class="btn btn-info btn-sm">
				<i class="fa fa-download"></i>
				#translateResource( uri="cms:assetmanager.download.btn" )#
			</button>
		</a>

		<a class="pull-right inline" data-global-key="a" id="upload-button">
			<button class="btn btn-success btn-sm">
				<i class="fa fa-cloud-upload"></i>
				#translateResource( uri="cms:assetmanager.add.version.btn" )#
			</button>
		</a>
		<form id="upload-version-form" action="#event.buildAdminLink( linkTo='assetManager.uploadNewVersionAction' )#" method="post" enctype="multipart/form-data" class="hide">
			<input type="hidden" name="asset" value="#assetId#">
			#renderForm(
				  formName  = "preside-objects.asset.newversion"
				, context   = "admin"
			)#
		</form>
	</div>

	<form id="edit-asset-form" class="form-horizontal edit-asset-form" data-auto-focus-form="true" data-dirty-form="protect" action="#event.buildAdminLink( linkto="assetmanager.editAssetAction" )#" method="post">
		<input type="hidden" name="asset" value="#( rc.asset ?: "" )#" />

		<div class="row">
			<div class="col-sm-8">
				<div class="well">
					#renderForm(
						  formName         = "preside-objects.asset.admin.edit"
						, formId           = "edit-asset-form"
						, context          = "admin"
						, savedData        = asset
						, validationResult = rc.validationResult ?: ""
					)#

					<br>

					<div class="pull-right">
						<a href="#event.buildAdminLink( linkTo="assetmanager", queryString="folder=#asset.asset_folder#" )#" class="btn cancel-asset-btn"><i class="fa fa-remove-sign"></i> #cancelBtnTitle#</a>
						<button type="input" class="btn btn-primary"><i class="fa fa-check"></i> #saveBtnTitle#</button>
					</div>

					<div class="clearfix"></div>
				</div>
			</div>

			<div class="col-sm-4">
				<figure>
					<div class="edit-asset-preview">
						#renderAsset( assetId=assetId, context="adminPreview" )#
					</div>
					<figcaption><em>#FileSizeFormat( asset.size )#, #asset.asset_type# file</em></figcaption>
				</figure>
			</div>
		</div>

	</form>
</cfoutput>