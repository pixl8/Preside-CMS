<cfscript>
	activeFolder = Trim( rc.folder  ?: "" );
	rootFolder   = prc.rootFolderId ?: 0;
	if ( not Len( activeFolder ) ) {
		activeFolder = rootFolder;
	}

	permissionContext   = prc.permissionContext ?: [];
</cfscript>

<cfoutput>
	<form action="#event.buildAdminLink( linkTo='assetManager.multiRecordAction' )#" method="post" id="multi-action-form">
		<input type="hidden" name="multiAction" value="">
		<table id="asset-listing-table" class="table table-hover table-striped asset-listing-table">
			<thead>
				<tr>
					<th class="center" data-width="50px">
						<label>
							<input type="checkbox" class="ace" />
							<span class="lbl"></span>
						</label>
					</th>
					<th data-field="title">#translateResource( "preside-objects.asset:title.singular" )#</th>
					<th data-width="200px" data-field="datemodified">#translateResource( "preside-objects.asset:field.datemodified.title" )#</th>
					<th data-width="100px">#translateResource( "cms:assetmanager.browser.table.actions.header" )#</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
			</tbody>
		</table>
		<div class="form-actions" id="multi-action-buttons">
			<button class="btn btn-danger confirmation-prompt" type="submit" name="delete" disabled="disabled" data-global-key="d" title="#translateResource( "cms:assetmanager.browser.deleteMulti.prompt" )#">
				<i class="fa fa-trash-o bigger-110"></i>
				#translateResource( "cms:assetmanager.browser.deleteMulti.btn" )#
			</button>

			<button class="btn btn-info" disabled="disabled" data-global-key="m" data-toggle="move-assets-dialog" data-target="move-assets-form" data-dialog-title="#translateResource( 'cms:assetmanager.move.multi.assets.dialog.title' )#">
				<i class="fa fa-folder bigger-110"></i>
				#translateResource( "cms:assetmanager.browser.moveMulti.btn" )#
			</button>
		</div>
	</form>
</cfoutput>