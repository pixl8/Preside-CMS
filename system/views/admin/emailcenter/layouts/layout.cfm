<cfscript>
	event.include( "/js/admin/specific/htmliframepreview/" );
	event.include( "/css/admin/specific/htmliframepreview/" );

	preview = prc.preview  ?: {};
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<li class="active">
					<a data-toggle="tab" href="##tab-html">
						<i class="fa fa-fw fa-code blue"></i>&nbsp;
						#translateResource( "cms:emailcenter.layouts.layout.preview.html" )#
					</a>
				</li>
				<li>
					<a data-toggle="tab" href="##tab-text">
						<i class="fa fa-fw fa-file-text-o grey"></i>&nbsp;
						#translateResource( "cms:emailcenter.layouts.layout.preview.text" )#
					</a>
				</li>
			</ul>

			<div class="tab-content">
				<div class="tab-pane active" id="tab-html">
					<div class="html-preview">
						<script id="htmlBody" type="text/template">#preview.html#</script>
						<iframe class="html-message-iframe" data-src="htmlBody" frameBorder="0" style="overflow:hidden;"></iframe>
					</div>
				</div>
				<div class="tab-pane" id="tab-text">
					<p><pre>#Trim( preview.text )#</pre></p>
				</div>
			</div>
		</div>
	</cfsavecontent>

	#renderView( view="/admin/emailcenter/layouts/_layoutTabs", args={ body=body, tab="preview" } )#
</cfoutput>