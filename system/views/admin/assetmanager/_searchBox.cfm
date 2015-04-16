<cfparam name="args.prefetchUrl" type="string" />
<cfparam name="args.remoteUrl"   type="string" />

<cfoutput>
	<label class="block clearfix" for="asset-search-box">
		<span class="block input-icon">
			<input type              = "text"
			       id                = "asset-search-box"
			       class             = "search-box form-control"
			       placeholder       = "#translateResource( 'cms:assetmanager.search.placeholder' )#"
			       name              = "q"
			       autocomplete      = "off"
			       data-global-key   = "s"
			       data-prefetch-url = "#args.prefetchUrl#"
			       data-remote-url   = "#args.remoteUrl#">

			<i class="fa fa-search"></i>
		</span>
	</label>
</cfoutput>