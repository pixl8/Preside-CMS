<cfparam name="args.logs" type="query" />
<cfscript>
	prevLogDate = Trim( rc.latestDate ?: "" );
	logDate     = prevLogDate.len() ? prevLogDate : DateFormat( args.logs.dateCreated[ 1 ], "yyyy-mm-dd" );
</cfscript>

<cfoutput>
	<cfif !prevLogDate.len()>
		#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = logDate } )#
	</cfif>
	<div class="timeline-items">
		<cfloop query="args.logs">
			<cfscript>
				auditTrailData = QueryRowToStruct( args.logs, args.logs.currentRow );
				auditTrailData.logDate = DateFormat( auditTrailData.datecreated, "yyyy-mm-dd" );
				if ( IsJson( auditTrailData.detail ) ) {
					auditTrailData.detail = DeserializeJson( auditTrailData.detail );
				}
				auditTrailData.userLink = event.buildAdminLink( linkto="auditTrail", queryString="user=" & auditTrailData.user );
			</cfscript>

			<cfif DateDiff( "d", auditTrailData.logDate, logDate )>
				<cfset logDate = auditTrailData.logDate />
				</div>
				#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = logDate } )#
				<div class="timeline-items">
			</cfif>

			#renderView( view="/admin/auditTrail/_log", args=auditTrailData )#
		</cfloop>
	</div>
</cfoutput>