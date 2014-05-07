<cfparam name="args.label" type="string" />
<cfparam name="args.id"    type="string" />

<cfoutput>
	<tr>
		<td class="folder-icon"><i class="fa fa-folder-open blue"></i></td>
		<td>
			<a class="folder-view-link" href="#event.buildAdminLink( linkTo="assetManager", queryString="folder=#args.id#")#"><span class="folder-name">#args.label#</span></a>
			<form class="edit-folder-form" action="#event.buildAdminLink( linkTo="assetManager.renameFolderAction" )#" method="post">
				<input type="hidden" name="folder" value="#args.id#" />

				#renderFormControl(
					  name         = "label"
					, type         = "textInput"
					, context      = "inline"
					, defaultValue = args.label
					, layout       = ""
				)#
			</form>
		</td>
		<td>
			<div class="action-buttons">
				<a class="blue rename-folder" href="##" data-context-key="e">
					<i class="fa fa-pencil bigger-130"></i>
				</a>
				<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="assetmanager.trashFolderAction", queryString="folder=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:assetmanager.trash.folder.link", data=[ urlEncodedFormat( args.label ) ] )#">
					<i class="fa fa-trash-o bigger-130"></i>
				</a>
			</div>
		</td>
	</tr>
</cfoutput>