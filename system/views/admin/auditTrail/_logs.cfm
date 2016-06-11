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
				thisLogDate    = DateFormat( auditTrailData.datecreated, "yyyy-mm-dd" );
				if ( IsJson( auditTrailData.detail ) ) {
					auditTrailData.detail = DeserializeJson( auditTrailData.detail );
				}
			</cfscript>

			<cfif DateDiff( "d", thisLogDate, logDate )>
				<cfset logDate = thisLogDate />
				</div>
				#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = logDate } )#
				<div class="timeline-items">
			</cfif>

			<div class="timeline-item clearfix" data-date="#thisLogDate#">
				<div class="timeline-info">
					<img class="user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( auditTrailData.email_address ) ) )#?r=g&d=mm&s=40" alt="" />
					<span class="label label-info label-sm">#TimeFormat( auditTrailData.datecreated, "HH:mm" )#</span>
				</div>
				<div class="widget-box transparent">
					#renderLogMessage( log=auditTrailData )#
				</div>
			</div>
		</cfloop>
	</div>
</cfoutput>