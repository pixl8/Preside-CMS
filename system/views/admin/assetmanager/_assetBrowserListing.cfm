<cfparam name="args.title" type="string" />
<cfparam name="args.id"    type="string" />

<cfoutput>
	<tr>
		<td>#renderAsset( assetId=args.id, context="icon" )#</td>
		<td>#args.title#</td>
		<td>
			<div class="action-buttons">
				<a class="blue" href="#event.buildAdminLink( linkto="assetmanager.editAsset", querystring="asset=#args.id#" )#" data-context-key="e">
					<i class="fa fa-pencil bigger-130"></i>
				</a>
				<a class="green" href="#event.buildLink( assetId=args.id )#" data-context-key="w" title="#translateResource( uri="cms:assetmanager.download.asset.link", data=[ urlEncodedFormat( args.title ) ] )#" target="_blank">
					<i class="fa fa-download bigger-130"></i>
				</a>
				<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashAssetAction", queryString="asset=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:assetmanager.trash.asset.link", data=[ urlEncodedFormat( args.title ) ] )#">
					<i class="fa fa-trash-o bigger-130"></i>
				</a>

			</div>
		</td>
	</tr>
</cfoutput>