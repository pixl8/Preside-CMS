<cfscript>
	log = prc.log;
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<h4>
			<a href="#event.buildAdminLink( linkTo="emailLogs" )#" data-global-key="b" title="#translateResource( "cms:viewEmailBody.link.title" )#">
				<button class="btn btn-primary btn-sm">
					<i class="fa fa-fw fa-reply"></i>&nbsp;
					#translateResource( uri="cms:viewEmailBody.link.backToEmailLog" )#
				</button>
			</a>
			<a class="pull-right inline red confirmation-prompt" href="#event.buildAdminLink( linkTo='emailLogs.deleteLogAction', queryString='id=' & log.id )#" data-global-key="c" title="#translateResource( "cms:emailLogs.delete.log.link" )#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash"></i>
					#translateResource( "cms:viewEmailBody.delete.button" )#
				</button>
			</a>
		</h4>
	</div>
	<h3 class="text-success">
		<i class="fa fa-fw fa-envelope-square"></i>
		#log.subject#
	</h3>
	<div class="alert alert-info">
		#translateResource( uri="cms:viewEmailBody.mail.details", data=[ dateTimeFormat( log.datecreated, "mmmm d, yyyy h:nn:ss tt" ), "<b>#log.from_address#</b>", "<b>#htmlEditFormat( log.to_address )#</b>" ] )#
	</div>
	<div class="container">
		<ul class="nav nav-tabs">
			<li class="active">
				<a data-toggle="tab" href="##html">
					<i class="fa fa-fw fa-html5"></i>
					#translateResource( "cms:viewEmailBody.html.tab.header" )#
				</a>
			</li>
			<li>
				<a data-toggle="tab" href="##text">
					<i class="fa fa-fw fa-file-text-o"></i>
					#translateResource( "cms:viewEmailBody.text.tab.header" )#
				</a>
			</li>
		</ul>
		<div class="tab-content">
			<div id="html" class="tab-pane fade in active">
				<script id="htmlBody" type="text/template">
					#log.html_body#
				</script>
				<pre>
					<iframe width="100%" data-src="htmlBody" frameborder="0"></iframe>
				</pre>
			</div>
			<div id="text" class="tab-pane fade">
				<pre>#log.text_body#</pre>
			</div>
		</div>
	</div>
</cfoutput>