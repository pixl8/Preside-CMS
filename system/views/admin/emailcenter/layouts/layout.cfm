<cfscript>
	event.include( "/js/admin/specific/htmliframepreview/" );
	event.include( "/css/admin/specific/htmliframepreview/" );

	preview = prc.preview  ?: {};
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<div class="row">
			<div class="col-lg-7 col-md-12">
				<h4 class="blue lighter">#translateResource( "cms:emailcenter.layouts.layout.preview.html" )#</h4>
				<div class="html-preview">
					<script id="htmlBody" type="text/template">#preview.html#</script>
					<iframe class="html-message-iframe" data-src="htmlBody" frameBorder="0" style="overflow:hidden;"></iframe>
				</div>
			</div>
			<div class="col-lg-5 col-md-12">
				<h4 class="blue lighter">#translateResource( "cms:emailcenter.layouts.layout.preview.text" )#</h4>
				<p><pre>#Trim( preview.text )#</pre></p>
			</div>
		</div>
	</cfsavecontent>

	#renderView( view="/admin/emailcenter/layouts/_layoutTabs", args={ body=body, tab="preview" } )#
</cfoutput>