<cfscript>
	activeFolder = Trim( rc.folder  ?: "" );
	rootFolder   = prc.rootFolderId ?: 0;
	if ( not Len( activeFolder ) ) {
		activeFolder = rootFolder;
	}

	permissionContext   = prc.permissionContext ?: [];
</cfscript>

<cfoutput>
	<table id="asset-listing-table" class="table table-hover asset-listing-table">
		<thead>
			<tr>
				<th data-width="50%" data-field="title">#translateResource( "preside-objects.asset:title.singular" )#</th>
				<th data-width="auto" data-field="datemodified">#translateResource( "preside-objects.asset:field.datemodified.title" )#</th>
				<th data-width="auto" data-field="datecreated">#translateResource( "preside-objects.asset:field.datecreated.title" )#</th>
				<th>&nbsp;</th>
			</tr>
		</thead>
		<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
		</tbody>
	</table>
</cfoutput>