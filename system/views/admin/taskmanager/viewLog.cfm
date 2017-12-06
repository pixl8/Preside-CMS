<cfscript>
	log = prc.log ?: {};
	canRunTasks = hasCmsPermission( "taskmanager.run" );
</cfscript>

<cfoutput>
	<cfif canRunTasks>
		<div class="top-right-button-group">
			<a id="run-task-btn" class="pull-right inline btn btn-info btn-sm<cfif IsFalse( log.complete )> btn-disabled</cfif>" href="#event.buildAdminLink( linkTo="taskmanager.runTaskAction", queryString="task=#log.task_key#" )#" data-global-key="r" <cfif IsFalse( log.complete )> disabled</cfif>>
				<i class="fa fa-rotate-right"></i>
				#translateResource( uri="cms:taskmanager.run.btn" )#
			</a>
		</div>
	</cfif>


	<div class="task-log">
		<pre id="taskmanager-log">#log.log#</pre>
	</div>
	<div class="pull-right log-actions">
		<span class="time-taken <cfif IsTrue( log.complete )>complete green<cfelse>running blue</cfif>">
			<i class="fa fa-fw fa-clock-o"></i>

			<span class="time-taken">#translateResource( "cms:taskamanager.log.timetaken" )#</span>
			<span class="running-for">#translateResource( "cms:taskamanager.log.runningfor" )#</span>

			<span class="time" id="task-log-timetaken">#log.time_taken#</span>

			<cfif IsFalse( log.complete ) and canRunTasks>
				<a id="kill-task-link" href="#event.buildAdminLink( linkTo='taskmanager.killRunningTaskAction', queryString='task=' & log.task_key )#" data-global-key="k" class="red confirmation-prompt kill-task" title="#HtmlEditFormat( translateResource( 'cms:taskmanager.killtask.prompt' ) )#">
					<i class="fa fa-fw fa-plug"></i>
					#translateResource( "cms:taskmanager.kill.task.btn")#
				</a>
			</cfif>
		</span>
	</div>
</cfoutput>