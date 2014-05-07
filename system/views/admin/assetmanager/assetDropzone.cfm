<cfscript>
	folder    = rc.folder ?: "";
	addAssetsUrl = event.buildAdminLink(
		  linkTo      = "assetManager.addAssets"
		, queryString = "folder=#folder#"
	);
	uploadTempFileUrl = event.buildAdminLink(
		linkTo = "assetManager.uploadTempFileAction"
	);
</cfscript>

<cfoutput>
	<form id="assetUploadDropzone" class="dropzone asset-upload-dropzone" action="#addAssetsUrl#" data-upload-url="#uploadTempFileUrl#" method="post">
		<div class="fallback">
			<input name="file" type="file" multiple="" />
		</div>
		<div class="dz-message">
			<div class="upload-buttons">
				<button type="reset" class="reset-btn btn btn-sm"><i class="fa fa-remove-sign"></i> #translateResource( "cms:assetManager.dropzone.cancel.button" )#</button>
				<button type="submit" class="upload-btn btn btn-sm btn-primary"><i class="fa fa-cloud-upload"></i> #translateResource( "cms:assetManager.dropzone.upload.button" )#</button>
			</div>
			<span class="upload-instructions bigger-120 bolder">
				#translateResource( "cms:assetManager.dropzone.instructions" )#<br />
				<i class="upload-icon fa fa-cloud-upload blue fa fa-3x"></i>
			</span>
		</div>
	</form>
</cfoutput>