<cfscript>
	preview = prc.preview ?: {};
	event.include( "/js/admin/specific/htmliframepreview/" );
	event.include( "/css/admin/specific/htmliframepreview/" );
</cfscript>

<cfoutput>
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<li class="active">
				<a data-toggle="tab" href="##tab-preview">
					<i class="fa fa-fw fa-eye blue"></i>&nbsp;
					Preview
				</a>
			</li>
			<li>
				<a data-toggle="tab" href="##tab-edit">
					<i class="fa fa-fw fa-pencil green"></i>&nbsp;
					Edit
				</a>
			</li>
			<li>
				<a data-toggle="tab" href="##tab-layout">
					<i class="fa fa-fw fa-cogs grey"></i>&nbsp;
					Layout configuration
				</a>
			</li>
		</ul>

		<div class="tab-content">
			<div class="tab-pane active" id="tab-preview">
				<h4 class="blue lighter">Subject: #( preview.subject ?: '' )#</h4>
				<div class="row">
					<div class="col-lg-7 col-md-12">
						<h4 class="blue lighter">HTML Preview</h4>
						<div class="html-preview">
							<script id="htmlBody" type="text/template">#preview.htmlBody#</script>
							<iframe class="html-message-iframe" data-src="htmlBody" frameBorder="0" style="overflow:hidden;"></iframe>
						</div>
					</div>
					<div class="col-lg-5 col-md-12">
						<h4 class="blue lighter">Plain text preview</h4>
						<p><pre>#Trim( preview.textBody )#</pre></p>
					</div>
				</div>
			</div>
			<div class="tab-pane" id="tab-edit">
				<p>TODO: edit</p>
			</div>
			<div class="tab-pane" id="tab-layout">
				<p>TODO: layout</p>
			</div>
		</div>
	</div>
</cfoutput>