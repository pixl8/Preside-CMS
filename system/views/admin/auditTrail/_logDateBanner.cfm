<cfparam name="args.logDate" type="date" />
<cfscript>
	daysOld = DateDiff( "d", args.logDate, DateFormat( Now(), "yyyy-mm-dd" ) );
</cfscript>

<cfoutput>
	<div class="timeline-label">
		<span class="label label-primary arrowed-in-right label-lg">
			<b>
				<cfif daysOld == 0>
					#translateResource( "cms:dates.today" )#
				<cfelseif daysOld == 1>
					#translateResource( "cms:dates.yesterday" )#
				<cfelse>
					#renderContent( renderer="date", data=args.logDate )#
				</cfif>
			</b>
		</span>
	</div>
</cfoutput>