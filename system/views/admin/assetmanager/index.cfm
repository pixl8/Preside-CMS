<cfscript>
	folder         = rc.folder ?: "";
	folderTitle    = prc.folder.label ?: translateResource( "cms:assetmanager.root.folder" );
	isSystemFolder = IsTrue( prc.folder.is_system_folder ?: "" );
	folderTree     = prc.folderTree ?: [];

	prc.pageIcon     = "picture-o";
	prc.pageTitle    = translateResource( "cms:assetManager" );
	prc.pageSubtitle = folderTitle;

</cfscript>

<cfoutput>
	<div class="top-right-button-group title-and-actions-container clearfix">
		#renderView( view="admin/assetmanager/_folderTitleAndActions", args={ folderId=folder, folderTitle=folderTitle, isSystemFolder=isSystemFolder } )#
	</div>
	<div id="browse" class="row">
		<div class="col-sm-5 col-md-4 col-lg-4">
			<div class="navigation-tree-container">
				<div class="preside-tree-nav tree tree-unselectable" data-nav-list="1" data-nav-list-child-selector=".tree-folder-header,.tree-item">
					<cfloop array="#folderTree#" index="node">
						#renderView( view="/admin/assetmanager/_treeFolderNode", args=node )#
					</cfloop>
				</div>
			</div>
		</div>
		<div class="col-sm-7 col-md-8 col-lg-8">
			#renderView( "admin/assetmanager/listingtable" )#
		</div>
	</div>
</cfoutput>

