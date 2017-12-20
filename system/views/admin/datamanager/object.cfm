<cfscript>
	objectName          = rc.id          ?: "";
	gridFields          = prc.gridFields ?: ["label","datecreated","datemodified"];
	batchEditableFields = prc.batchEditableFields ?: {};
	canDelete           = IsTrue( prc.canDelete      ?: "" );
	isMultilingual      = IsTrue( prc.isMultilingual ?: "" );
	draftsEnabled       = IsTrue( prc.draftsEnabled  ?: "" );

	topRightButtons = prc.topRightButtons ?: "";
</cfscript>
<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName          = objectName
		, useMultiActions     = canDelete
		, multiActionUrl      = event.buildAdminLink( linkTo='datamanager.multiRecordAction', querystring="object=#objectName#" )
		, batchEditableFields = batchEditableFields
		, gridFields          = gridFields
		, isMultilingual      = isMultilingual
		, draftsEnabled       = draftsEnabled
		, allowDataExport     = true
	} )#
</cfoutput>