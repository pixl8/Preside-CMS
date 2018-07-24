<cfscript>
	interactionStats = args.interactionStats ?: {};
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
				<div id="email-interaction-stats"></div>
				<cfsavecontent variable="chartJs">
					var data = [{
						  x           : #SerializeJson( interactionStats.dates )#
						, y           : #SerializeJson( interactionStats.sent )#
						, name        : "Emails sent"
						, mode        : 'lines+markers'
						, line        : {color: 'orange'}
					},{
						  x           : #SerializeJson( interactionStats.dates )#
						, y           : #SerializeJson( interactionStats.delivered )#
						, name        : "Emails delivered"
						, mode        : 'lines+markers'
						, line        : {color: 'blue'}
					},{
						  x           : #SerializeJson( interactionStats.dates )#
						, y           : #SerializeJson( interactionStats.opened )#
						, name        : "Emails opened"
						, mode        : 'lines+markers'
						, line        : {color: 'green'}
					},{
						  x           : #SerializeJson( interactionStats.dates )#
						, y           : #SerializeJson( interactionStats.failed )#
						, name        : "Emails failed"
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
			</div>
		</div>
	</div>
</cfoutput>