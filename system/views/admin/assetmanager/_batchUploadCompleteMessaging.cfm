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
			<a class="btn btn-success return-to-folder-link" href="#event.buildAdminLink( linkTo='assetmanager', queryString='folder=' )#">
				<i class="fa fa-check bigger-110"></i>
				#translateResource( "cms:assetManager.upload.back.to.folder" )#
			</a>

			<a class="btn btn-default start-over-link" href="#event.buildAdminLink( linkTo='assetmanager.uploadAssets', queryString='folder=' )#">
				<i class="fa fa-mail-reply bigger-110"></i>
				#translateResource( "cms:assetManager.upload.restart" )#
			</a>
		</div>
	</div>
</cfoutput>