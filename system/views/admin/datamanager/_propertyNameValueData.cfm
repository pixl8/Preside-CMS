<!---@feature admin--->
<cfscript>
	viewHelper = getModel( "adminDataViewsService" );
	objectName = args.objectName ?: "";
	fields     = args.fields     ?: [];
	detail     = args.detail     ?: {};
	extraRows  = args.extraRows  ?: [];
</cfscript>
<cfoutput>
	<cfsavecontent variable="rows">
		<cfloop array="#fields#" index="i" item="field">
			<cfset rendered = viewHelper.renderField( objectName=objectName, propertyName="#field#", recordId=prc.recordId, value=( detail[ field ] ?: '' ) )/>
			<cfif Len( Trim( rendered ) )>
				<tr>
					<th style="width:20em;">
						#translatePropertyName( objectName, field )#:</th>
					<td>#rendered#</td>
				</tr>
			</cfif>
		</cfloop>
		<cfloop array="#extraRows#" index="i" item="extraRow">
			<tr>
				<th style="width:20em;">#extraRow.title#</th>
				<td>#extraRow.body#</td>
			</tr>
		</cfloop>
	</cfsavecontent>
	<cfif rows.trim().len()>
		<div class="table-responsive">
			<table class="table table-condensed table-no-header table-non-clickable table-admin-view-record">
				<tbody>
					<cfloop array="#fields#" index="i" item="field">
						<cfset rendered = viewHelper.renderField( objectName=objectName, propertyName="#field#", recordId=prc.recordId, value=( detail[ field ] ?: '' ) )/>

						<cfif Len( Trim( rendered ) ) and Len( detail[ field ] )>
							<tr>
								<th style="width:20em;">
									#translatePropertyName( objectName, field )#:</th>
								<td>#rendered#</td>
							</tr>
						</cfif>
					</cfloop>
					<cfloop array="#extraRows#" index="i" item="extraRow">
						<tr>
							<th style="width:20em;">#extraRow.title#</th>
							<td>#extraRow.body#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</cfif>
</cfoutput>