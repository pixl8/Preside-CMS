<cfscript>
	canDelete  = IsTrue( prc.canDelete ?: "" );
	avlButtons = prc.avlButtons ?: [];
</cfscript>

<cfoutput>
	<cfif isArray( avlButtons ) && !arrayIsEmpty( avlButtons )>
		<div class="top-right-button-group">
			<cfloop array="#avlButtons#" item="btn">
				<a class="pull-right inline" href="#btn.link#" data-global-key="#btn.globalKey ?: ""#">
					<button class="btn #btn.btnClass#">
						<i class="fa #btn.iconClass#"></i>
						#btn.btnLabel#
					</button>
				</a>
			</cfloop>
		</div>
	</cfif>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = "formbuilder_form"
		, gridFields      = [ "name", "description", "locked", "active", "active_from", "active_to" ]
		, datasourceUrl   = event.buildAdminLink( "formbuilder.getFormsForAjaxDataTables" )
		, useMultiActions = canDelete
		, multiActionUrl  = event.buildAdminLink( "formbuilder.multiRecordAction" )
	} )#
</cfoutput>