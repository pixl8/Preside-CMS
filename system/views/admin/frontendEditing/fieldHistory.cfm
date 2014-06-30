<cfscript>
	param name="prc.history"           type="query";
	param name="prc.versionObjectName" type="string";
</cfscript>

<cfoutput>
	<cfif !prc.history.recordCount>
		<em>#translateResource( 'cms:frontendeditor.field.history.no.history')#</em>
	<cfelse>
		<table class="field-version-table">
			<thead>
				<tr>
					<th>#translateResource( 'cms:frontendeditor.field.history.versiondate.heading' )#</th>
					<th>#translateResource( 'cms:frontendeditor.field.history.versionauthor.heading' )#</th>
					<th>#translateResource( 'cms:frontendeditor.field.history.versionactions.heading' )#</th>
				</tr>
			</thead>

			<tbody>
				<cfloop query="prc.history">
					<tr>
						<td>#renderField( object=prc.versionObjectName, property="datecreated", data=prc.history.dateCreated, context="admindatatable" )#</td>
						<td>#renderField( object=prc.versionObjectName, property="_version_author", data=prc.history._version_author, context="admindatatable" )#</td>
						<td>&nbsp;</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfif>
</cfoutput>