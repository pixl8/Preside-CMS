<!---@feature admin and adhocTasks--->
<cfscript>
	taskId         = rc.taskId ?: "";
	task           = prc.task ?: QueryNew('');
	taskProgress   = prc.taskProgress ?: {};
	status         = taskProgress.status ?: "";
	progress       = Round( Val( taskProgress.progress ) );
	log            = taskProgress.log;
	timeTaken      = taskProgress.timeTaken;
	lineCount      = taskProgress.lineCount;

	hideTaskLog = isTrue( rc.hideTaskLog ?: "" );
	hideCancel  = isTrue( rc.hideCancel  ?: "" );
	hideReturn  = isTrue( rc.hideReturn  ?: "" ) && Len( taskProgress.resultUrl ?: "" );

	canCancel    = IsTrue( prc.canCancel ?: "" ) && !hideCancel;
	hasReturnUrl = Len( Trim( taskProgress.returnUrl ) ) && !hideReturn;
	succeeded    = status == "succeeded";
	isRunning    = status == "running";
	isPending    = status == "pending";

	if ( canCancel ) {
		cancelAction = event.buildAdminLink( linkto="adhocTaskManager.cancelTaskAction", querystring="taskId=" & taskId );
		cancelPrompt = HtmlEditFormat( translateResource( "cms:adhoctaskmanager.progress.cancel.task.prompt" ) );
	}

	progressClass = "danger";
	switch( status ) {
		case "pending":
		case "running":
		case "succeeded":
			progressClass = "success";
	}

	event.include( "/css/admin/specific/taskmanager/" );
	if ( isRunning || isPending ) {
		event.include( "/js/admin/specific/adhoctaskprogress/" );
		event.includeData({
			  adhocTaskStatusUpdateUrl = event.buildAdminLink( linkto="adhocTaskManager.status", queryString="taskId=#taskId#" )
			, adhocTaskLineCount       = lineCount
		} );
	}
</cfscript>
<cfoutput>
	<div id="ad-hoc-task-progress-container">
		<div class="progress pos-rel <cfif isRunning> progress-striped active</cfif>" data-percent="#progress#%">
			<div class="progress-bar progress-bar-#progressClass#" style="width:#progress#%;"></div>
		</div>
		<cfif !hideTaskLog>
			<div class="task-log">
				<pre id="taskmanager-log">#log#</pre>
			</div>
		</cfif>
		<div class="clearfix">
			<div class="pull-right log-actions">
				<span class="time-taken <cfif succeeded>complete green<cfelseif isRunning>running blue<cfelseif isPending>orange<cfelse>red</cfif>">
					<i class="fa fa-fw fa-clock-o"></i>

					<span class="time-taken">#translateResource( "cms:taskamanager.log.timetaken" )#</span>
					<cfif isRunning>
						<span class="running-for">#translateResource( "cms:taskamanager.log.runningfor" )#</span>
					</cfif>

					<span class="time" id="task-log-timetaken">#timeTaken#</span>
				</span>
			</div>
		</div>

		<div class="form-actions row">
			<cfif hasReturnUrl>
				<a href="#task.return_url#" class="btn btn-info">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:adhoctaskmanager.progress.return.btn" )#
				</a>
			</cfif>
			<cfif canCancel>
				<a href="#cancelAction#" class="btn btn-danger confirmation-prompt" title="#cancelPrompt#" id="task-cancel-button">
					<i class="fa fa-ban bigger-110"></i>
					#translateResource( "cms:adhoctaskmanager.progress.cancel.task.btn" )#
				</a>
			</cfif>
		</div>
	</div>
</cfoutput>