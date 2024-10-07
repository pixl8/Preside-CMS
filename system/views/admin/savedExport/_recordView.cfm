<!---@feature admin and dataExport--->
<cfscript>
	record         = args.record         ?: {};
	objI18nBase    = args.objI18nBase    ?: "";
	exportSchedule = args.exportSchedule ?: {};
	hasHistory     = args.hasHistory     ?: false;
</cfscript>

<cfoutput>
	<cfif !isEmpty( record.description ?: "" )>
		<p>#record.description#</p>
	</cfif>

	<dl class="dl-horizontal">
		<dt>#translateResource( uri=objI18nBase & "field.template.title", defaultValue="" )#</dt>
		<dd>
			#renderEnum( record.template, "dataExportTemplate" )#
		</dd>
		<cfif !isEmpty( exportSchedule )>
			<dt>#translateResource( uri=objI18nBase & "recordview.exportschedule.title", defaultValue="" )#</dt>
			<dd>#( translateResource( uri=objI18nBase & "recordview.exportschedule.text", defaultValue="", data=[ exportSchedule.readable ?: "" ] ) )#</dd>
		</cfif>
		<cfif !isEmpty( record.saved_filter ?: "" )>
			<dt>#translateResource( uri=objI18nBase & "recordview.exportFilter.title", defaultValue="" )#</dt>
			<dd class="no-margin-bottom">
				<cfloop list="#record.saved_filter#" item="filter" index="curIndex">
					#renderLabel( "rules_engine_condition", filter )##( curIndex neq listLen( record.saved_filter ) ? ", " : "" )#
				</cfloop>
			</dd>
		</cfif>
		<cfif !isEmpty( record.fields ?: "" ) and !isEmpty( record.object_name ?: "" )>
			<dt>#translateResource( uri=objI18nBase & "recordview.exportField.title", defaultValue="" )#</dt>
			<dd>
				<cfloop list="#record.fields#" item="field" index="fieldIndex">
					#translatePropertyName( objectName=record.object_name, propertyName=field )##( fieldIndex neq listLen( record.fields ) ? ", " : "" )#
				</cfloop>
			</dd>
		</cfif>
	</dl>


	<div class="tabbable">
		<ul class="nav nav-tabs" role="tablist">
			<li role="presentation" class="active">
				<a data-toggle="tab" href="##tab-history">
					<i class="fa fa-fw fa-clock blue"></i>
					#translateResource( uri=objI18nBase & "recordview.exportHistory.title", defaultValue="" )#
				</a>
			</li>
		</ul>
		<div class="tab-content">
			<div id="tab-history" class="tab-pane active">
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
	</ul>
</cfoutput>