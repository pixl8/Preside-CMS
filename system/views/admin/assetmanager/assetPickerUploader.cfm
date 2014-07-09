<cfscript>
	addAssetsUrl      = event.buildAdminLink( linkTo = "assetManager.addAssetsInPicker"    );
	uploadTempFileUrl = event.buildAdminLink( linkTo = "assetManager.uploadTempFileAction" );
</cfscript>

<cfoutput>
	<div class="alert alert-info">
		<p><i class="fa fa-lg fa-cloud-upload"></i> #translateResource( uri="cms:assetmanager.uploader.step1.title" )#</p>
	</div>

	<form id="assetUploadDropzone" class="dropzone asset-upload-dropzone asset-picker-upload-form" action="#addAssetsUrl#" data-upload-url="#uploadTempFileUrl#" method="post">
		<div class="fallback">
			<input name="file" type="file" multiple="" />
		</div>
		<div class="dz-message">
			<span class="upload-instructions bigger-120 bolder">
				#translateResource( "cms:assetManager.dropzone.instructions" )#<br />
				<i class="upload-icon fa fa-cloud-upload blue fa fa-3x"></i>
			</span>
		</div>
	</form>
</cfoutput>