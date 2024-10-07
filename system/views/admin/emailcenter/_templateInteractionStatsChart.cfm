<!---@feature admin and emailCenter--->
<cfscript>
	interactionStats = args.interactionStats ?: {};
	statsAvailable   = isTrue( args.statsAvailable ?: "" );
	showPanel        = isTrue( args.showPanel ?: true );
</cfscript>
<cfoutput>
	<cfif showPanel>
		<div class="widget-box">
			<div class="widget-header">
				<h4 class="widget-title lighter smaller">
					<i class="fa fa-fw fa-line-chart"></i>
					#translateResource( "cms:emailcenter.stats.history.box.title" )#
				</h4>
			</div>

			<div class="widget-body">
				<div class="widget-main padding-20">
	</cfif>

	<cfif not statsAvailable>
		<br>
		<p class="text-center light-grey"><em>#translateResource( "cms:emailcenter.stats.history.box.no.stats" )#</em></p>
	<cfelse>
		<div class="table-responsive">
			<div id="email-interaction-stats"></div>
		</div>
		<cfsavecontent variable="chartJs">
			var data = #SerializeJson( args.interactionStatsData ?: [] )#
			var layout = {
				  margin      : { t : 60 }
				, font        : { size : 11 }
				, showlegend  : true
				, legend      : { traceorder : "normal", orientation : "h", x : 0, y : 1, yanchor : "bottom", borderwidth : 5, bordercolor : "##fff" }
				, xaxis       : { tickangle : 45, type : "date", gridwidth : 1 }
				, yaxis       : { title : "Activity" }
			};
			var config = {
				displayModeBar : false
			};

			Plotly.newPlot( 'email-interaction-stats', data, layout, config );
		</cfsavecontent>
		<cfset event.includeInlineJs( chartJs ) />
	</cfif>

	<cfif showPanel>
				</div>
			</div>
		</div>
	</cfif>
</cfoutput>