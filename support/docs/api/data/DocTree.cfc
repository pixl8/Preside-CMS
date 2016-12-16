component accessors=true {

	property name="tree"    type="array";
	property name="idMap"   type="struct";
	property name="pathMap" type="struct";

	public any function init( required string rootDirectory ) {
		_loadTree( arguments.rootDirectory );
		return this;
	}

	public any function getPage( required string id ) {
		return idMap[ arguments.id ] ?: NullValue();
	}

	public any function getPageByPath( required string path ) {
		return pathMap[ arguments.path ] ?: NullValue();
	}

	public boolean function pageExists( required string id ) {
		return idMap.keyExists( arguments.id );
	}

	public array function getPagesByCategory( required string category ) {
		var matchedPages = [];

		for( var id in idMap ) {
			var pageCategories = idMap[ id ].getCategories();

			if ( !IsNull( pageCategories ) && pageCategories.indexOf( arguments.category ) != -1 ) {
				matchedPages.append( idMap[ id ] );
			}
		}

		return matchedPages;
	}

	public array function sortPagesByType( required array pages ) {
		return arguments.pages.sort( function( pageA, pageB ) {
			if ( pageA.getPageType() > pageB.getPageType() ) {
				return 1;
			}
			if ( pageA.getPageType() < pageB.getPageType() ) {
				return -1;
			}

			return pageA.getTitle() > pageB.getTitle() ? 1 : -1;
		} );
	}

// private helpers
	private void function _loadTree( required string rootDirectory ) {
		_initializeEmptyTree();

		var pageFiles = _readPageFilesFromDocsDirectory( arguments.rootDirectory );
		for( var pageFile in pageFiles ) {
			page = _preparePageObject( pageFile, arguments.rootDirectory );

			_addPageToTree( page );
		}
		_sortChildren( tree );
		_calculateNextAndPreviousPageLinks( tree );
	}

	private void function _initializeEmptyTree() {
		setTree( [] );
		setIdMap( {} );
		setPathMap( {} );
	}

	private void function _addPageToTree( required any page ) {
		var parent    = _getPageParent( arguments.page );
		var ancestors = [];
		var lineage   = [];

		if ( !IsNull( parent ) ) {
			parent.addChild( arguments.page );
			arguments.page.setParent( parent );

			ancestors = parent.getAncestors();
			ancestors.append( parent.getId() );
		} else {
			tree.append( arguments.page );
		}

		arguments.page.setAncestors( ancestors );
		lineage = Duplicate( ancestors );
		lineage.append( arguments.page.getId() );
		arguments.page.setLineage( lineage );

		idMap[ arguments.page.getId() ]     = arguments.page;
		pathMap[ arguments.page.getPath() ] = arguments.page;
	}

	private array function _readPageFilesFromDocsDirectory( required string rootDirectory ) {
		var pageFiles = DirectoryList( arguments.rootDirectory, true, "path", "*.md" );

		pageFiles = _removeRootDirectoryFromFilePaths( pageFiles, arguments.rootDirectory );
		pageFiles = _removeHiddenPages( pageFiles );
		pageFiles = _sortPageFilesByDepth( pageFiles );

		return pageFiles;
	}

	private array function _removeRootDirectoryFromFilePaths( required any pageFiles, required string rootDirectory ) {
		var args = arguments;

		return args.pageFiles.map( function( path ){
			return path.replace( args.rootDirectory, "" );
		} );
	}

	private array function _removeHiddenPages( required any pageFiles ) {
		for( var i = pageFiles.len(); i > 0; i-- ){
			if ( ReFindNoCase( "/_", pageFiles[ i ] ) ) {
				pageFiles.deleteAt( i );
			}
		}

		return pageFiles;
	}

	private array function _sortPageFilesByDepth( required array pageFiles ) {
		arguments.pageFiles.sort( function( page1, page2 ){
			var depth1 = page1.listLen( "\/" );
			var depth2 = page2.listLen( "\/" );

			if ( depth1 == depth2 ) {
				return page1 > page2 ? 1 : -1;
			}

			return depth1 > depth2 ? 1 : -1;
		} );

		return arguments.pageFiles;
	}

	private any function _preparePageObject( required string pageFilePath, required string rootDirectory ) {
		var pageData = new PageReader().readPageFile( arguments.rootDirectory & pageFilePath )
		var page = new Page( argumentCollection=pageData );

		page.setPath( _getPagePathFromMdFilePath( arguments.pageFilePath ) )
		if ( !page.getId().len() ) {
			page.setId( page.getPath() );
		}

		page.setChildren( [] );
		page.setDepth( ListLen( page.getPath(), "/" ) );

		return page;
	}

	private string function _getPagePathFromMdFilePath( required string filePath ) {
		var fileDir = GetDirectoryFromPath(  arguments.filePath );
		var parts   = fileDir.listToArray( "\/" );

		for( var i=1; i <= parts.len(); i++ ) {
			if ( parts[ i ].listLen( "." ) > 1 ) {
				parts[ i ] = parts[ i ].listRest( "." );
			}
		}

		return "/" & parts.toList( "/" );
	}

	private string function _getParentPagePathFromPagePath( required string pagePath ) {
		var parts = arguments.pagePath.listToArray( "/" );
		parts.deleteAt( parts.len() );

		return "/" & parts.toList( "/" );
	}

	private any function _getPageParent( required any page ) {
		var parentPath = _getParentPagePathFromPagePath( arguments.page.getPath() );

		return getPageByPath( parentPath );
	}

	private void function _sortChildren( required array children ){
		children.sort( function( childA, childB ) {
			if ( childA.getSortOrder() == childB.getSortOrder() ) {
				return childA.getTitle() > childB.getTitle() ? 1 : -1;
			}
			return childA.getSortOrder() > childB.getSortOrder() ? 1 : -1;
		} );


		for( var child in children ) {
			_sortChildren( child.getChildren() );
		}
	}

	private void function _calculateNextAndPreviousPageLinks( required array pages, any nextParentPage, any lastPageTouched ) {
		var pageCount = arguments.pages.len();

		for( var i=1; i <= pageCount; i++ ) {
			var page = arguments.pages[i];

			if ( i==1 ) {
				page.setPreviousPage( arguments.lastPageTouched ?: NullValue() );
			} else {
				page.setPreviousPage( arguments.pages[i-1] );
			}

			if( page.getChildren().len() ) {
				page.setNextPage( page.getChildren()[1] );
			} else if ( i == pageCount ) {
				page.setNextPage( arguments.nextParentPage ?: NullValue() );
			} else {
				page.setNextPage( arguments.pages[i+1] );
			}

			arguments.lastPageTouched = page;

			var nextParent = ( i == pageCount ) ? ( arguments.nextParentPage ?: NullValue() ) : arguments.pages[i+1];
			for( var child in page.getChildren() ){
				_calculateNextAndPreviousPageLinks( page.getChildren(), ( nextParent ?: NullValue() ), arguments.lastPageTouched )
			}
		}
	}
}