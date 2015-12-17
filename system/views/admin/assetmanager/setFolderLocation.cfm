<cfscript>
	folderId       = rc.folder ?: "";
	formId         = "set-folder-location";
	postFormAction = event.buildAdminLink( "assetmanager.setFolderLocationAction" );
	cancelAction   = event.buildAdminLink( linkto="assetmanager", queryString="folder=" & folderId );
</cfscript>

<cfoutput>
	<div class="top-right-button-group title-and-actions-container clearfix">
		<div class="pull-right">
			<a class="inline" href="#event.buildAdminLink( linkTo="assetmanager.managelocations" )#">
				<button class="btn btn-default btn-sm">
					<i class="fa fa-cogs"></i>
					#translateResource( "cms:assetmanager.manage.locations.button" )#
				</button>
			</a>
		</div>
	</div>

	<p class="alert alert-warning">
		<i class="fa fa-fw fa-exclamation-triangle"></i>
		#translateResource( 'cms:assetmanager.set.location.warning' )#
	</p>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#postFormAction#">
		<input type="hidden" name="folder" value="#folderId#" />

		#renderForm(
			  formName          = "preside-objects.asset_folder.admin.setlocation"
			, context           = "admin"
			, formId            = formId
			, savedData         = prc.record ?: {}
			, validationResult  = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:assetManager.set.folder.submit.btn")#
				</button>
			</div>
		</div>
	</form>
</cfoutput>