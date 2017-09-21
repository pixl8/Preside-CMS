<cfparam name="prc.log" type="struct" />
<cfoutput>
	<p class="align-right">
		<a href="#event.buildAdminLink( linkTo="emailCenter.logs.resendEmail", queryString='id=#prc.log.id#"' )#" class="btn btn-primary">Resend this email</a>
	</p>
	<div class="tabbable tabs-left">
		<ul class="nav nav-tabs">
			<li class="active">
				<a data-toggle="tab" href="##tab-html">
					<i class="fa fa-fw fa-code blue"></i>&nbsp;
					#translateResource( "cms:emailcenter.systemTemplates.template.preview.html" )#
				</a>
			</li>
			<li>
				<a data-toggle="tab" href="##tab-text">
					<i class="fa fa-fw fa-file-text-o grey"></i>&nbsp;
					#translateResource( "cms:emailcenter.systemTemplates.template.preview.text" )#
				</a>
			</li>
		</ul>
		<div class="tab-content">
			<div class="tab-pane active" id="tab-html">
				<div class="html-preview">
					<script id="htmlBody" type="text/template">#prc.log.email_content_html#</script>
					<iframe class="html-message-iframe" data-src="htmlBody" frameBorder="0" style="overflow:hidden;"></iframe>
				</div>
			</div>
			<div class="tab-pane" id="tab-text">
				<p><pre>#Trim( prc.log.email_content_text )#</pre></p>
			</div>
		</div>
	</div>
	<script>
		inlineIframeHandler();
	</script>
</cfoutput>
