component {
	public string function renderLink( any page, required string title ) {

		if ( IsNull( arguments.page ) ) {
			return '<a class="missing-link">#HtmlEditFormat( arguments.title )#</a>';
		}

		var link = ReReplace( page.getPath(), "^/", "" ) & ".html";

		return '<a href="#link#">#HtmlEditFormat( arguments.title )#</a>';
	}

	public void function build( docTree, buildDirectory ) {
		var tree = docTree.getTree();

		for( var page in tree ) {
			_writePage( page, arguments.buildDirectory, docTree );
		}

		_renderStaticPages( arguments.buildDirectory, arguments.docTree );
		_copyStaticAssets( arguments.buildDirectory );
		_copySiteImages( arguments.buildDirectory );
		_writeSearchIndex( arguments.docTree, arguments.buildDirectory );
	}

	public string function renderPage( required any page, required any docTree ){
		try {
			var renderedPage = renderTemplate(
				  template = "templates/#_getPageLayoutFile( arguments.page )#.cfm"
				, args     = { page = arguments.page, docTree=arguments.docTree }
				, helpers  = "/builders/html/helpers"
			);
		} catch( any e ) {
			e.additional.docsPageId = arguments.page.getid();
			rethrow;
		}
		var crumbs = [];
		var parent = arguments.page.getParent();
		var links = [];


		while( !IsNull( parent ) ) {
			crumbs.prepend( parent.getId() );
			parent = parent.getParent();
		}

		if ( !IsNull( arguments.page.getCategories() ) ) {
			for( var category in arguments.page.getCategories() ) {
				if ( arguments.docTree.pageExists( "category-" & category ) ) {
					links.append( "[[category-" & category & "]]" );
				}
			}
		}
		if ( !IsNull( arguments.page.getRelated() ) ) {
			for( var link in arguments.page.getRelated() ) {
				links.append( link );
			}
		}

		return renderTemplate(
			  template = "layouts/main.cfm"
			, helpers  = "/builders/html/helpers"
			, args     = {
				  body       = Trim( renderedPage )
				, page       = arguments.page
				, crumbs     = renderTemplate( template="layouts/breadcrumbs.cfm", helpers  = "/builders/html/helpers", args={ crumbs=crumbs, page=arguments.page } )
				, navTree    = renderTemplate( template="layouts/sideNavTree.cfm", helpers  = "/builders/html/helpers", args={ crumbs=crumbs, docTree=arguments.docTree, pageLineage=arguments.page.getLineage() } )
				, seeAlso    = renderTemplate( template="layouts/seeAlso.cfm"    , helpers  = "/builders/html/helpers", args={ links=links } )
			  }
		);
	}

	public string function renderSearchIndex( required any docTree ) {
		var pages           = arguments.docTree.getIdMap();
		var searchIndex     = [];

		for( var pageId in pages ) {
			var page = pages[ pageId ];
			var icon = "";

			switch( page.getPageType() ){
				case "function":
				case "object":
				case "presideobject":
				case "form":
					icon = "code";
					break;
				default:
					icon = "file-o";
			}

			searchIndex.append( {
				  "value"   = page.getPath() & ".html"
				, "display" = page.getTitle()
				, "text"    = HtmlEditFormat( page.getTitle() )
				, "type"    = page.getPageType()
				, "icon"    = icon
			} );
		}

		return SerializeJson( searchIndex );
	}

// PRIVATE HELPERS
	private void function _writePage( required any page, required string buildDirectory, required any docTree ) {
		var filePath      = _getHtmlFilePath( arguments.page, arguments.buildDirectory );
		var fileDirectory = GetDirectoryFromPath( filePath );

		if ( !DirectoryExists( fileDirectory ) ) {
			DirectoryCreate( fileDirectory );
		}

		FileWrite( filePath, renderPage( arguments.page, arguments.docTree ) );

		for( var childPage in arguments.page.getChildren() ) {
			_writePage( childPage, arguments.buildDirectory, arguments.docTree );
		}
	}

	private string function _getHtmlFilePath( required any page, required string buildDirectory ) {
		if ( arguments.page.getPath() == "/home" ) {
			return arguments.buildDirectory & "/index.html";
		}

		return arguments.buildDirectory & arguments.page.getPath() & ".html";
	}

	private void function _copyStaticAssets( required string buildDirectory ) {
		DirectoryCopy( GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/assets", arguments.buildDirectory & "/assets", true, function( path ){
			return !path.find( "node_modules" ) && !path.find( "/sass" ) && !path.find( "Gruntfile.js" ) && !path.find( "package.json" ) && !path.find( ".gitignore" ) && !path.find( ".sass-cache" );
		} );
	}

	private void function _copySiteImages( required string buildDirectory ) {
		DirectoryCopy( "/docs/_images", arguments.buildDirectory & "/images", true, "*", true  );
	}

	private void function _renderStaticPages( required string buildDirectory, required any docTree ) {
		var staticPagesDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/staticPages";
		var _404Page = _renderStaticPage( staticPagesDir & "/404.html", "404 - Page not found", arguments.docTree );

		FileWrite( buildDirectory & "/404.html", _404Page );
	}

	private void function _writeSearchIndex( required any docTree, required string buildDirectory ) {
		var searchIndexFile = arguments.buildDirectory & "/assets/js/searchIndex.json";

		FileWrite( searchIndexFile, renderSearchIndex( arguments.docTree ) );
	}

	private string function _getPageLayoutFile( required any page ) {
		return "page";
	}

	private string function _renderStaticPage( required string filePath, required string pageTitle, required any docTree ){
		var renderedPage = FileRead( arguments.filePath );
		var crumbs = [];
		var links = [];

		return renderTemplate(
			  template = "layouts/static.cfm"
			, helpers  = "/builders/html/helpers"
			, args     = {
				  body       = Trim( renderedPage )
				, title      = arguments.pageTitle
				, crumbs     = renderTemplate( template="layouts/staticbreadcrumbs.cfm", helpers  = "/builders/html/helpers", args={ title=arguments.pageTitle } )
				, navTree    = renderTemplate( template="layouts/sideNavTree.cfm", helpers  = "/builders/html/helpers", args={ crumbs=crumbs, docTree=arguments.docTree, pageLineage=[ "/home" ] } )
			  }
		);
	}
}