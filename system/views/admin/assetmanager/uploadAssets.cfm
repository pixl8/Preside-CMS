<cfscript>
	prc.pageIcon     = "picture";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubTitle = translateResource( "cms:assetmanager.upload.assets.title" );

	folderQS = 'folder=#( rc.folder ?: "" )#';

	event.addAdminBreadCrumb(
		  title = prc.pageSubTitle
		, link  = event.buildAdminLink( linkTo="assetmanager.uploadAssets", queryString=folderQS )
	);

	rc.asset_folder = rc.folder ?: "";
</cfscript>

<cfoutput>
	<form id="add-assets-form" class="form-horizontal batch-add-assets-form" action="#event.buildAdminLink( linkto="assetmanager.uploadAssetAction" )#" method="post">
		#renderView( view="/admin/assetmanager/_uploadSteps", args={ activeStep=1 } )#

		<div class="row">
			<div class="col-md-5">
				<h3 class="upload-options-title">
					#translateResource( "cms:assetmanager.upload.steps.batch.upload.options.title")#
				</h3>
				<div class="upload-options">
					<p>#translateResource( "cms:assetmanager.upload.steps.batch.upload.options.description")#</p>
					<br>
					#renderForm(
						  formName         = "preside-objects.asset.group.upload"
						, context          = "admin"
						, formId           = "add-assets-form"
						, validationResult = rc.validationResult ?: ''
					)#

					<div class="form-actions row">
						<div class="col-md-offset-2">
							<a class="btn btn-info choose-files-trigger" tabindex="#getNextTabIndex()#">
								<i class="fa fa-plus bigger-110"></i>
								#translateResource( "cms:assetManager.dropzone.choose.files.button" )#
							</a>
							<a class="btn btn-success upload-files-trigger" tabindex="#getNextTabIndex()#" disabled>
								<i class="fa fa-cloud-upload bigger-110"></i>
								#translateResource( "cms:assetManager.dropzone.upload.button" )#
							</a>
						</div>
					</div>
				</div>

				<div class="hide upload-progress">
					<p>#translateResource( "cms:assetmanager.upload.steps.batch.upload.progress.description" )#</p>

					<div class="progress progress-striped active total-progress" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" style="width:' + progressBarWidth + 'px;">
						<div class="progress-bar progress-bar-success" style="width:0%;"></div>
					</div>
				</div>
				<div class="hide upload-results">
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
								#translateResource( "cms:assetManager.uplaod.restart" )#
							</a>
						</div>
					</div>
				</div>
			</div>
			<div class="col-md-7">
				<div class="table-responsive">
					<table class="table table-hover">
						<thead>
							<tr>
								<th style="width:75px;">Preview</th>
								<th colspan="4">Details</th>
							</tr>
						</thead>
						<tbody id="upload-previews">
						</tbody>
					</table>

					<p class="no-files-chosen-message text-center grey">
						<em>Choose files to begin</em>
					</p>
				</div>
			</div>
		</div>

		<script type="text/template" id="file-preview-template">
			#renderView( "/admin/assetmanager/_uploadPreviewTemplate" )#
		</script>
	</form>
</cfoutput>