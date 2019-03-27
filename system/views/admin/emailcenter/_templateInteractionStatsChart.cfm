<cfscript>
	interactionStats = args.interactionStats ?: {};
	statsAvailable   = IsTrue( args.statsAvailable ?: "" );
</cfscript>
<cfoutput>
	<div class="widget-box">
		<div class="widget-header">
			<h4 class="widget-title lighter smaller">
				<i class="fa fa-fw fa-line-chart"></i>
				#translateResource( "cms:emailcenter.stats.history.box.title" )#
			</h4>
		</div>

		<div class="widget-body">
			<div class="widget-main padding-20">
				<cfif not statsAvailable>
					<br>
					<p class="text-center light-grey"><em>#translateResource( "cms:emailcenter.stats.history.box.no.stats" )#</em></p>
				<cfelse>
					<div class="table-responsive">
						<div id="email-interaction-stats"></div>
					</div>
					<cfsavecontent variable="chartJs">
						var data = [{
							  x           : #SerializeJson( interactionStats.dates )#
							, y           : #SerializeJson( interactionStats.sent )#
							, name        : "#translateResource( 'cms:emailcenter.stats.chart.sent' )#"
							, mode        : 'lines+markers'
							, line        : {color: 'orange'}
						},{
							  x           : #SerializeJson( interactionStats.dates )#
							, y           : #SerializeJson( interactionStats.delivered )#
							, name        : "#translateResource( 'cms:emailcenter.stats.chart.delivered' )#"
							, mode        : 'lines+markers'
							, line        : {color: 'blue'}
						},{
							  x           : #SerializeJson( interactionStats.dates )#
							, y           : #SerializeJson( interactionStats.opened )#
							, name        : "#translateResource( 'cms:emailcenter.stats.chart.opened' )#"
							, mode        : 'lines+markers'
							, line        : {color: 'green'}
						},{
							  x           : #SerializeJson( interactionStats.dates )#
							, y           : #SerializeJson( interactionStats.clicks )#
							, name        : "#translateResource( 'cms:emailcenter.stats.chart.clicks' )#"
							, mode        : 'lines+markers'
							, line        : {color: 'yellow'}
						},{
							  x           : #SerializeJson( interactionStats.dates )#
							, y           : #SerializeJson( interactionStats.failed )#
							, name        : "#translateResource( 'cms:emailcenter.stats.chart.failed' )#"
							, mode        : 'lines+markers'
							, line        : {color: 'red'}
						}];
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
			</div>
		</div>
	</div>
</cfoutput>