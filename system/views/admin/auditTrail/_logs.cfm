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

				auditTrailData.actionLink      = event.buildAdminLink( linkto="auditTrail", queryString="action=" & auditTrailData.action );
				auditTrailData.actionTitle     = translateResource( uri="auditlog.#auditTrailData.type#:#auditTrailData.action#.title", defaultValue=action.action );
				auditTrailData.actionIconClass = translateResource( uri="auditlog.#auditTrailData.type#:#auditTrailData.action#.iconClass" );

				auditTrailData.typeLink      = event.buildAdminLink( linkto="auditTrail", queryString="type=" & auditTrailData.type );
				auditTrailData.typeTitle     = translateResource( uri="auditlog.#auditTrailData.type#:title", defaultValue=auditTrailData.type );
				auditTrailData.typeIconClass = translateResource( uri="auditlog.#auditTrailData.type#:iconClass" );

				if ( Len( Trim( auditTrailData.record_id ) ) ) {
					auditTrailData.recordLink = event.buildAdminLink( linkto="auditTrail", queryString="recordId=" & auditTrailData.record_id );
				}
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