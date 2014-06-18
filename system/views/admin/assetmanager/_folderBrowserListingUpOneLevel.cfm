<cfparam name="args.parent_folder" type="string" />

<cfoutput>
	<tr>
		<td class="folder-icon"><i class="fa fa-folder-open blue"></i></td>
		<td><a href="#event.buildAdminLink( linkTo="assetManager", queryString="folder=#args.parent_folder#")#">..</a></td>
		<td>&nbsp;</td>
	</tr>
</cfoutput>