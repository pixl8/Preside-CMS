<!---@feature admin and assetManager--->
<cfscript>
	assetId = prc.assetId ?: "";

	event.include( "/js/admin/specific/assetmanager/chunkedUpload/" )
	     .include( "/css/admin/specific/assetmanager/uploadassets/" )
	     .includeData( { parallelUploads=1 } );
</cfscript>

<cfoutput>
	<form id="add-assets-form" class="form-horizontal batch-add-assets-form" action="#event.buildAdminLink( linkto='chunkedUpload.uploadChunk' )#" method="post">
		<input type="hidden" name="asset_id" value="#assetId#">

		#renderView( view="/admin/assetmanager/_uploadSteps", args={ activeStep=1 } )#

		<div class="table-responsive">
			<table class="table table-hover">
				<tbody id="upload-previews"></tbody>
			</table>

			<p class="no-files-chosen-message text-center grey">
				<a class="btn btn-info choose-files-trigger" tabindex="#getNextTabIndex()#">
					<i class="fa fa-plus bigger-110"></i>
					#translateResource( "cms:assetManager.dropzone.choose.files.button" )#
				</a>
				<br><br>
				<em class="drag-drop-instructions">#translateResource( "cms:assetManager.dropzone.drag.drop.instructions" )#</em>
			</p>
		</div>

		<div class="text-center" style="margin-top:15px;">
			<a class="btn btn-success upload-files-trigger" tabindex="#getNextTabIndex()#" disabled="disabled">
				<i class="fa fa-cloud-upload bigger-110"></i>
				#translateResource( "cms:assetManager.dropzone.upload.button" )#
			</a>
		</div>

		<div class="hide upload-progress" style="margin-top:15px;">
			#renderView( "/admin/assetmanager/_batchUploadProgressBar" )#
		</div>
		<div class="hide upload-results">
			#renderView( "/admin/assetmanager/_batchUploadCompleteMessaging" )#
		</div>

		<script type="text/template" id="file-preview-template">
			<tr class="asset-preview">
				<td class="upload-type">{{{type}}}</td>
				<td class="upload-size">{{{size}}}</td>
				<td class="upload-detail">{{name}}</td>
				<td class="upload-actions">
					<div class="action-buttons">
						<a class="red cancel-file-trigger" href="##">
							<i class="fa fa-trash-o bigger-130"></i>
						</a>
					</div>
				</td>
			</tr>
		</script>
	</form>
</cfoutput>
