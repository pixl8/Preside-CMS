<cfscript>
	assetId      = rc.asset                  ?: "";
	asset        = prc.asset                 ?: StructNew();
	assetType    = prc.assetType             ?: QueryNew( "" );
	versions     = prc.versions              ?: QueryNew( "" );
	isImageAsset = prc.isImageAsset          ?: false;
	failedQueue  = prc.latestFailedQueueItem ?: QueryNew( '' );

	prc.pageIcon     = "picture-o";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.edit.asset.title" );

	event.addAdminBreadCrumb(
		  title = translateResource( "cms:assetmanager.edit.asset.title" )
		, link  = event.buildAdminLink( linkTo="assetmanager.editAsset", queryString="asset=#assetId#" )
	);

	saveBtnTitle = translateResource( "cms:assetManager.add.asset.form.save.button" );
	cancelBtnTitle = translateResource( "cms:assetManager.add.asset.form.cancel.button" );

	permissionContext = prc.permissionContext ?: [];
	hasDeletePermission  = hasCmsPermission( permissionKey="assetmanager.assets.delete" , context="assetmanagerfolder", contextKeys=permissionContext );
	hasDownloadPermission  = hasCmsPermission( permissionKey="assetmanager.assets.download" , context="assetmanagerfolder", contextKeys=permissionContext );
	canTranslate       = prc.canTranslate      ?:false;
	assetTranslations  = prc.assetTranslations ?: [];
	translateUrlBase   = event.buildAdminLink( linkTo="assetManager.translateAssetRecord", queryString="object=asset&id=#assetId#&language=" );

	tooLargeForDerivatives = IsTrue( prc.tooLargeForDerivatives ?: "" );
	tooLargeMessage        = prc.tooLargeMessage ?: "";
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif canTranslate && assetTranslations.len()>
			<button data-toggle="dropdown" class="btn btn-sm btn-info pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-globe"></i>&nbsp; #translateResource( uri="cms:assetManager.translate.record.btn" )#
			</button>

			<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
				<cfloop array="#assetTranslations#" index="i" item="language">
					<li>
						<a href="#translateUrlBase##language.id#">
							<i class="fa fa-fw fa-pencil"></i>&nbsp; #language.name# (#translateResource( 'cms:multilingal.status.#language.status#' )#)
						</a>
					</li>
				</cfloop>
			</ul>
		</cfif>
		<cfif hasDeletePermission>
			<a class="pull-right inline confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashAssetAction", queryString="asset=#assetId#")#" data-global-key="d" title="#HtmlEditFormat( translateResource( uri="cms:assetmanager.trash.asset.link", data=[ asset.title ] ) )#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash-o"></i>
					#translateResource( uri="cms:assetmanager.delete.btn" )#
				</button>
			</a>
		</cfif>

		<a class="pull-right inline" href="#event.buildAdminLink( linkTo="assetmanager.clearAssetDerivativesAction", queryString="asset=#assetId#")#" title="#translateResource( "cms:assetmanager.clear.derivatives.prompt" )#">
			<button class="btn btn-info btn-sm">
				<i class="fa fa-redo"></i>
				#translateResource( uri="cms:assetmanager.clear.derivatives.btn" )#
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
			#renderFormControl(
				  name    = "file"
				, type    = "fileupload"
				, accept  = assetType.mimetype
				, context = "admin"
				, id      = "upload-version-file"
				, label   = "cms:assetmanager.newversion.form.file.label"
			)#
		</form>
	</div>

	<cfif failedQueue.recordCount>
		<div class="alert alert-danger">
			<p><i class="fa fa-fw fa-exclamation-triangle"></i>
				#translateResource( "cms:assetmanager.generated.asset.errors" )#
			</p>
			<p>
				<a href="#event.buildAdminLink( linkto="assetmanager.dismissQueueErrorsAction", queryString="id=#assetId#" )#" class="btn btn-warning">
					<i class="fa fa-fw fa-refresh"></i>
					#translateResource( "cms:assetmanager.generated.asset.dismiss.errors" )#
				</a>
				<a href="##full-error-detail" data-toggle="collapse">
					<i class="fa fa-fw fa-caret-right"></i>
					#translateResource( "cms:assetmanager.generated.asset.show.errors" )#
				</a>
			</p>
			<br>
			<div class="collapse" id="full-error-detail">
				<div class="well">
					#renderView( view="/general/_errorDetail", args={ error=DeserializeJson( failedQueue.last_error ) } )#
				</div>
			</div>
		</div>
	</cfif>

	<cfif tooLargeForDerivatives>
		<div class="alert alert-danger">
			<p><i class="fa fa-fw fa-exclamation-triangle"></i>
				#tooLargeMessage#
			</p>
		</div>
	</cfif>

	<div class="row">
		<div class="col-sm-12 col-m-6 col-lg-7">
			<form id="edit-asset-form" class="form-horizontal edit-asset-form" data-auto-focus-form="true" data-dirty-form="protect" action="#event.buildAdminLink( linkto="assetmanager.editAssetAction" )#" method="post">
				<input type="hidden" name="asset" value="#( rc.asset ?: "" )#" />

				#renderForm(
					  formName          = "preside-objects.asset.admin.edit"
					, mergeWithFormName = isImageAsset ? "preside-objects.asset.cropping" : ""
					, formId            = "edit-asset-form"
					, context           = "admin"
					, savedData         = asset
					, validationResult  = rc.validationResult ?: ""
				)#

				<br>

				<div class="pull-right">
					<a href="#event.buildAdminLink( linkTo="assetmanager", queryString="folder=#asset.asset_folder#" )#" class="btn cancel-asset-btn"><i class="fa fa-remove-sign"></i> #cancelBtnTitle#</a>
					<button type="input" class="btn btn-primary"><i class="fa fa-check"></i> #saveBtnTitle#</button>
				</div>

				<div class="clearfix"></div>
			</form>
		</div>

		<div class="col-sm-12 col-m-6 col-lg-5">
			<div class="well">
				<cfif versions.recordCount>
					<div id="version-carousel" class="owl-carousel owl-theme">
						<cfloop query="versions">
							<cfset version = QueryRowToStruct( versions, versions.currentRow ) />
							<cfset version.isCurrentVersion = version.id == asset.active_version />
							<cfset version.hasDownloadPermission = hasDownloadPermission>
							<cfset version.hasDeletePermission = hasDeletePermission>
							#renderView( view="/admin/assetmanager/_assetVersionPreview", args=version )#
						</cfloop>
					</div>
				<cfelse>
					<cfset version                  = Duplicate( asset ) />
					<cfset version.asset            = version.id />
					<cfset version.id               = "" />
					<cfset version.isCurrentVersion = true />
					<cfset version.version_number   = 1 />
					<cfset version.hasDownloadPermission = hasDownloadPermission>
					<cfset version.hasDeletePermission = hasDeletePermission>

					#renderView( view="/admin/assetmanager/_assetVersionPreview", args=version )#
				</cfif>
		</div>
	</div>
</cfoutput>