<cfoutput>
	<div class="alert alert-success complete-success">
		<p><i class="fa fa-fw fa-check"></i> #translateResource( 'cms:assetmanager.upload.success.message' )#</p>
	</div>
	<div class="alert alert-warning partial-success">
		<p><i class="fa fa-fw fa-info-circle"></i> #translateResource( 'cms:assetmanager.upload.partial.success.message' )#</p>
	</div>
	<div class="alert alert-danger complete-failure">
		<p><i class="fa fa-fw fa-exclamation-triangle"></i> #translateResource( 'cms:assetmanager.upload.failure.message' )#</p>
	</div>
	<div class="form-actions row">
		<div class="col-md-offset-2">
			<a class="btn btn-success select-assets-link" href="##">
				<i class="fa fa-check bigger-110"></i>
				#translateResource( "cms:assetManager.upload.picker.completed.button" )#
			</a>
		</div>
	</div>
</cfoutput>