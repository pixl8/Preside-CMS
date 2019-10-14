<cfscript>
	heartbeats = args.heartbeats ?: {};
</cfscript>

<cfoutput>
	<cfif !heartbeats.count()>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( "cms:systemInformation.no.heartbeats.running" )#
		</p>
	<cfelse>
		<div class="table-responsive">
			<table class="table table-striped">
				<thead>
					<tr>
						<th>#translateResource( "cms:systemInformation.heartbeats.table.title.th"   )#</th>
						<th>#translateResource( "cms:systemInformation.heartbeats.table.up.th"      )#</th>
						<th>#translateResource( "cms:systemInformation.heartbeats.table.uptime.th"  )#</th>
						<th>#translateResource( "cms:systemInformation.heartbeats.table.lastrun.th" )#</th>
					</tr>
				</thead>
				<tbody>
					<cfloop collection="#heartbeats#" item="heartbeat" index="heartbeatName">
						<tr>
							<td>#heartbeatName#</td>
							<td>#renderContent( "boolean", heartbeat.isUp, [ "adminDatatable", "admin" ] )#</td>
							<td>
								<i class="fa fa-fw fa-clock orange"></i>&nbsp;
								#renderContent( "taskTimeTaken", heartbeat.uptime, [ "accurate", "adminDatatable", "admin" ] )#
							</td>
							<td>
								<i class="fa fa-fw fa-clock purple"></i>&nbsp;
								#renderContent( "datetime", heartbeat.lastRun, [ "relative", "admin" ] )#
								<em class="light-grey">(#renderContent( "datetime", heartbeat.lastRun, [ "adminDatatable", "admin" ] )#)</em>
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</cfif>
</cfoutput>