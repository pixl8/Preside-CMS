<cfparam name="args.logs" type="query" />
<cfscript>
	firstLogDate = args.logs.dateCreated[ 1 ];
</cfscript>
<cfoutput>
	#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = firstLogDate } )#
	<div class="timeline-items">
		<cfloop query="args.logs">
			<cfscript>
				auditTrailData = QueryRowToStruct( args.logs, args.logs.currentRow );
				if ( IsJson( auditTrailData.detail ) ) {
					auditTrailData.detail = DeserializeJson( auditTrailData.detail );
				}
			</cfscript>

			<cfif DateDiff( "d", auditTrailData.datecreated, firstLogDate )>
				<cfset firstLogDate = auditTrailData.datecreated />

				#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = firstLogDate } )#
			</cfif>

			<div class="timeline-item clearfix">
				<div class="timeline-info">
					<img class="nav-user-photo" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( auditTrailData.email_address ) ) )#?r=g&d=mm&s=40" alt="Avatar for #HtmlEditFormat( auditTrailData.known_as )#" />
					<span class="label label-info label-sm">#TimeFormat( auditTrailData.datecreated, "HH:mm" )#</span>
				</div>
				<div class="widget-box transparent">
					#renderLogMessage( log=auditTrailData )#
				</div>
			</div>
		</cfloop>
	</div>
</cfoutput>