<cfscript>
	pageTitle          = args.pageTitle          ?: "";
	presideCmsVersion  = args.presideCmsVersion  ?: "";
	applicationServer  = args.applicationServer  ?: "";
	java               = args.java               ?: "";
	os                 = args.os                 ?: "";
	dataBase           = args.dataBase           ?: "";
</cfscript>

<cfoutput>
	<table class="table">
		<thead>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.cms.th" )#</th>
				<th>#translateResource( uri="cms:systemInformation.applicationServer.th" )#</th>
				<th>#translateResource( uri="cms:systemInformation.dataBase.th" )#</th>
				<th>#translateResource( uri="cms:systemInformation.java.th" )#</th>
				<th>#translateResource( uri="cms:systemInformation.os.th" )#</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td>#presideCmsVersion#</td>
				<td>#applicationServer#</td>
				<td>#dataBase#</td>
				<td>#java#</td>
				<td>#os#</td>
			</tr>
		</tbody>
	</table>
</cfoutput>