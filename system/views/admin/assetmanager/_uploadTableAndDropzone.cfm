<cfoutput>
	<div class="table-responsive">
		<table class="table table-hover">
			<thead>
				<tr>
					<th style="width:75px;">#translateResource( "cms:assetmanager.file.preview.table.header.preview" )#</th>
					<th colspan="4">#translateResource( "cms:assetmanager.file.preview.table.header.details" )#</th>
				</tr>
			</thead>
			<tbody id="upload-previews">
			</tbody>
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
</cfoutput>