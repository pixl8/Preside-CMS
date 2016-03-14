<cfparam name="args" type="struct"/>
<cfset args = deserializeJSON(args.data)>
<cfoutput>
	<table class="table formbuilder-response table-striped">
		<tr>
			<th>#translateResource( "cms:auditTrail.action" )#</th>
			<td>#args.action#</td>
		</tr>
		<tr>
			<th>#translateResource( "cms:auditTrail.type" )#</th>
			<td>#args.type#</td>
		</tr>
		<tr>
			<th>#translateResource( "cms:auditTrail.detail" )#</th>
			<td>#args.detail#</td>
		</tr>
		<tr>
			<th>#translateResource( "cms:auditTrail.Date&Time" )#</th>
			<td>#datetimeformat(args.datecreated,"medium")#</td>
		</tr>
	</table>
</cfoutput>