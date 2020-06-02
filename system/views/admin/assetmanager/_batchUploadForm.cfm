<cfscript>
	rc.asset_folder = rc.folder ?: "";
</cfscript>

<cfoutput>
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
</cfoutput>