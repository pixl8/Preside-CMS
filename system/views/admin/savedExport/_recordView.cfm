<cfscript>
	record         = args.record         ?: {};
	objI18nBase    = args.objI18nBase    ?: "";
	exportSchedule = args.exportSchedule ?: {};
	hasHistory     = args.hasHistory     ?: false;
</cfscript>

<cfoutput>
	<div class="row">
		<div class="col-md-12">
			<cfif !isEmpty( record.description ?: "" )>
				<p>#record.description#</p>
			</cfif>

			<cfif !isEmpty( exportSchedule )>
				<h4>#translateResource( uri=objI18nBase & "recordview.exportschedule.title", defaultValue="" )#</h4>
				<p>#( translateResource( uri=objI18nBase & "recordview.exportschedule.text", defaultValue="", data=[ exportSchedule.readable ?: "" ] ) )#</p>
			</cfif>
		</div>
	</div>

	<div class="row">
		<cfif !isEmpty( record.saved_filter ?: "" )>
			<div class="col-md-6">
				<h4>#translateResource( uri=objI18nBase & "recordview.exportFilter.title", defaultValue="" )#</h4>
				<div class="well">
					<p class="no-margin-bottom">
						<cfloop list="#record.saved_filter#" item="filter" index="curIndex">
							#renderLabel( "rules_engine_condition", filter )##( curIndex neq listLen( record.saved_filter ) ? ", " : "" )#
						</cfloop>
					</p>
				</div>
			</div>
		</cfif>

		<cfif !isEmpty( record.fields ?: "" ) and !isEmpty( record.object_name ?: "" )>
			<div class="col-md-6">
				<h4>#translateResource( uri=objI18nBase & "recordview.exportField.title", defaultValue="" )#</h4>
				<div class="well">
					<p class="no-margin-bottom">
						<cfloop list="#record.fields#" item="field" index="fieldIndex">
							#translatePropertyName( objectName=record.object_name, propertyName=field )##( fieldIndex neq listLen( record.fields ) ? ", " : "" )#
						</cfloop>
					</p>
				</div>
			</div>
		</cfif>
	</div>

	<div class="row">
		<div class="col-md-12">
			<h4 class="block">#translateResource( uri=objI18nBase & "recordview.exportHistory.title", defaultValue="" )#</h4>
		</div>
		<div class="col-md-12">
			<cfif isTrue( hasHistory )>
				#objectDataTable( objectName="saved_export_history", args={
					  allowSearch       = false
					, allowFilter       = false
					, defaultPageLength = 5
				} )#
			<cfelse>
				<p>#translateResource( uri=objI18nBase & "recordview.noExportHistory.message", defaultValue="" )#</p>
			</cfif>
		</div>
	</div>
</cfoutput>