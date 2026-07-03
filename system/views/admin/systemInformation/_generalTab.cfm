<!---@feature admin--->
<cfscript>
	pageTitle          = args.pageTitle          ?: "";
	presideCmsVersion  = args.presideCmsVersion  ?: "";
	applicationServer  = args.applicationServer  ?: "";
	java               = args.java               ?: "";
	os                 = args.os                 ?: "";
	dataBase           = args.dataBase           ?: "";
	timezoneId         = args.timezoneId         ?: "";
	timezoneShortName  = args.timezoneShortName  ?: "";
	timezoneName       = args.timezoneName       ?: "";
	utcHourOffset      = args.utcHourOffset      ?: "";
</cfscript>

<cfoutput>
	<table class="table table-no-header">
		<tbody>
			<tr>
				<th style="min-width:20em;">#translateResource( uri="cms:systemInformation.cms.th" )#</th>
				<td style="width: 100%;">#presideCmsVersion#</td>
			</tr>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.applicationServer.th" )#</th>
				<td>#applicationServer#</td>
			</tr>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.dataBase.th" )#</th>
				<td>#dataBase#</td>
			</tr>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.java.th" )#</th>
				<td>#java#</td>
			</tr>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.os.th" )#</th>
				<td>#os#</td>
			</tr>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.timezoneId.th" )#</th>
				<td>#timezoneId#</td>
			</tr>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.timezoneName.th" )#</th>
				<td>#timezoneName# (#timezoneShortName#)</td>
			</tr>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.timezoneOffset.th" )#</th>
				<td>UTC #utcHourOffset#</td>
			</tr>
			<tr>
				<th>#translateResource( uri="cms:systemInformation.timezoneTime.th" )#</th>
				<td>#DateTimeFormat( Now(), "yyyy-mm-dd HH:nn:ss" )#</td>
			</tr>
		</tbody>
	</table>
</cfoutput>