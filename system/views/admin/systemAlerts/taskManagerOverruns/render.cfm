<cfscript>
	overruns = args.overruns ?: [];
</cfscript>

<cfoutput>
	<cfif ArrayLen( overruns )>
		<table class="table">
			<tr>
				<th>#translateResource( "systemAlerts.taskManagerOverruns:table.heading.task" )#</th>
				<th>#translateResource( "systemAlerts.taskManagerOverruns:table.heading.runtime" )#</th>
				<th>#translateResource( "systemAlerts.taskManagerOverruns:table.heading.averagetime" )#</th>
			</tr>
			<cfloop array="#overruns#" item="overrun">
				<cfscript>
					taskKey         = overrun.taskKey         ?: "";
					historyId       = overrun.historyId       ?: "";
					taskLabel       = overrun.label           ?: "";
					runTime         = overrun.runTime         ?: 0;
					averageWorkTime = overrun.averageWorkTime ?: 0;
				</cfscript>
				<tr>
					<td>
						<a href="#event.buildAdminLink( linkTo="taskManager.viewLog", querystring="id=" & historyId )#">
							#taskLabel#
						</a>
					</td>
					<td>#DecimalFormat(runTime/60)#</td>
					<td>#DecimalFormat(averageWorkTime/60)#</td>
				</tr>
			</cfloop>
		</table>
	<cfelse>
		<p>#translateResource( "systemAlerts.taskManagerOverruns:no.tasks.overrunning.message" )#</p>
	</cfif>
</cfoutput>