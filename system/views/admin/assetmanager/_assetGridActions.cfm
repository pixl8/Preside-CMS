<cfparam name="args.title"        type="string" />
<cfparam name="args.id"           type="string" />
<cfparam name="args.asset_folder" type="string" />
<cfscript>
	permissionContext = prc.permissionContext ?: [];

	hasEditPermission  = hasCmsPermission( permissionKey="assetmanager.assets.edit" , context="assetmanagerfolder", contextKeys=permissionContext );
	hasDeletePermission  = hasCmsPermission( permissionKey="assetmanager.assets.delete" , context="assetmanagerfolder", contextKeys=permissionContext );
	hasDownloadPermission  = hasCmsPermission( permissionKey="assetmanager.assets.download" , context="assetmanagerfolder", contextKeys=permissionContext );
</cfscript>

<cfoutput>
	<cfif hasEditPermission>
		<a class="blue" href="#event.buildAdminLink( linkto="assetmanager.editAsset", querystring="asset=#args.id#" )#" data-context-key="e">
		<i class="fa fa-fw fa-pencil"></i></a>
	</cfif>

	<a class="grey" href="##move-assets-form" data-context-key="m" data-asset-id="#args.id#" data-folder-id="#args.asset_folder#" data-toggle="move-assets-dialog" data-dialog-title="#translateResource( uri='cms:assetmanager.move.single.asset.dialog.title', data=[ htmlEditFormat( args.title ) ] )#">
		<i class="fa fa-fw fa-folder-o"></i></a>

	<cfif hasDownloadPermission>
		<a class="green" href="#event.buildLink( assetId=args.id )#" data-context-key="w" title="#translateResource( uri="cms:assetmanager.download.asset.link", data=[ htmlEditFormat( args.title ) ] )#" target="_blank">
			<i class="fa fa-fw fa-download"></i></a>
	</cfif>

	<cfif hasDeletePermission>
		<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashAssetAction", queryString="asset=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:assetmanager.trash.asset.link", data=[ urlEncodedFormat( args.title ) ] )#">
			<i class="fa fa-fw fa-trash-o"></i></a>
	</cfif>

</cfoutput>