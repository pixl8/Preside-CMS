<!---@feature admin and assetManager--->
<cfscript>
	uploadCompleteView = prc.uploadCompleteView ?: '/admin/assetmanager/_batchUploadCompleteMessaging';

	event.include( "/js/admin/specific/assetmanager/uploadassets/"  )
         .include( "/css/admin/specific/assetmanager/uploadassets/" )
         .includeData( { parallelUploads=Val( getSystemSetting( "asset-manager", "max_parallel_uploads", 5 ) ) } );
</cfscript>

<cfoutput>
	<form id="add-assets-form" class="form-horizontal batch-add-assets-form" action="#event.buildAdminLink( linkto="assetmanager.uploadAssetAction" )#" method="post">
		#outputView( view="/admin/assetmanager/_uploadSteps", args={ activeStep=1 } )#

		<div class="row">
			<div class="col-md-5">
				<h3 class="upload-options-title">
					#translateResource( "cms:assetmanager.upload.steps.batch.upload.options.title")#
				</h3>

				<div class="upload-options">
					#outputView( '/admin/assetmanager/_batchUploadForm' )#
				</div>
				<div class="hide upload-progress">
					#outputView( '/admin/assetmanager/_batchUploadProgressBar' )#
				</div>
				<div class="hide upload-results">
					#outputView( uploadCompleteView )#
				</div>
			</div>
			<div class="col-md-7">
				#outputView( '/admin/assetmanager/_uploadTableAndDropzone' )#
			</div>
		</div>

		<script type="text/template" id="file-preview-template">
			#outputView( "/admin/assetmanager/_uploadPreviewTemplate" )#
		</script>
	</form>
</cfoutput>