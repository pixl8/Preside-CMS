<cfparam name="args.action"           type="string" />
<cfparam name="args.known_as"         type="string" />
<cfparam name="args.userLink"         type="string" />

<cfscript>
	args.userLink  = '<a href="#args.userLink#">#args.known_as#</a>';

	switch( args.action ) {
		case "add_folder":
		case "edit_folder":
		case "trash_folder":
		case "edit_asset_folder_admin_permissions":
			echo( renderView( view="/renderers/content/auditLogEntry/assetFolder", args=args ) );
		break;

		case "add_asset":
		case "add_asset_version":
		case "edit_asset":
		case "move_assets":
		case "restore_assets":
		case "trash_asset":
		case "permanently_delete_asset":
		case "change_asset_version":
		case "delete_asset_version":
			echo( renderView( view="/renderers/content/auditLogEntry/asset", args=args ) );
		break;
	}
</cfscript>