/**
 * The Update Manager Service provides the APIs
 * for managing the installed version of core Preside
 * for your application.
 *
 */
component output=false autodoc=true displayName="Update manager service" {

// constructor
	/**
	 * @repositoryUrl.inject              coldbox:setting:updateRepositoryUrl
	 * @systemConfigurationService.inject systemConfigurationService
	 * @applicationReloadService.inject   applicationReloadService
	 *
	 */
	public any function init(
		  required string repositoryUrl
		, required any    systemConfigurationService
		, required any    applicationReloadService
		,          string presidePath="/preside"

	) output=false {
		_setRepositoryUrl( arguments.repositoryUrl );
		_setSystemConfigurationService( arguments.systemConfigurationService );
		_setApplicationReloadService( arguments.applicationReloadService );
		_setPresidePath( arguments.presidePath );
		_setActiveDownloads( {} );

		return this;
	}

// public methods
	public string function getCurrentVersion() output=false {
		var versionFile = ListAppend( _getPresidePath(), "version.json", "/" );
		var versionInfo = "";

		if ( !FileExists( versionFile ) ) {
			return "unknown";
		}

		try {
			versionInfo = DeSerializeJson( FileRead( versionFile ) );
		} catch ( any e ) {
			return "unknown";
		}

		return versionInfo.version ?: "unknown";
	}

	public string function getLatestVersion() output=false {
		var versions = listAvailableVersions();

		if ( versions.len() ) {
			versions.sort( function( a, b ){
				return a.version > b.version ? 1 : -1;
			} );

			return versions[ versions.len() ].version;
		}

		return "unknown";
	}

	public array function listAvailableVersions() output=false {
		var s3Listing         = "";

		try {
			s3Listing = _fetchS3BucketListing();
		} catch ( any e ) {
			return [];
		}

		var branchPath        = _getRemoteBranchPath();
		var xPath             = "/:ListBucketResult/:Contents/:Key[starts-with(.,'#branchPath#')]/text()";
		var versionFiles      = XmlSearch( s3Listing, xPath );
		var jsonAndZipMatches = {};
		var versions          = [];

		for( var versionFilePath in versionFiles ) {
			versionFilePath = versionFilePath.xmlText;

			if ( ReFindNoCase( "\.(zip|json)$", versionFilePath ) ) {
				var fileKey  = ReReplace( versionFilePath, "^(.*)\.(zip|json)$", "\1" );
				var fileType = ReReplace( versionFilePath, "^(.*)\.(zip|json)$", "\2" );

				jsonAndZipMatches[ fileKey ][ fileType ] = true;
			}
		}

		for( var fileKey in jsonAndZipMatches ) {
			if ( jsonAndZipMatches[ fileKey ].keyExists( "json" ) && jsonAndZipMatches[ fileKey ].keyExists( "zip" ) ) {
				var versionInfo = _fetchVersionInfo( fileKey & ".json" );
				versionInfo.path = fileKey & ".zip";
				versionInfo.downloaded = versionIsDownloaded( versionInfo.version );

				versions.append( versionInfo );
			}
		}

		return versions;
	}

	public array function listDownloadedVersions() output=false {
		var containerDirectory = _getVersionContainerDirectory();
		var childDirectories   = DirectoryList( containerDirectory, false, "query" );
		var versions           = [];

		for( var dir in childDirectories ){
			if ( dir.type == "Dir" ) {
				var versionFile = containerDirectory & dir.name & "/version.json";
				if ( FileExists( versionFile ) ) {
					try {
						var versionInfo = DeSerializeJson( FileRead( versionFile ) );
						versionInfo.path = ExpandPath( containerDirectory & dir.name );
						versions.append( versionInfo );
					} catch( any e ) {}
				}
			}
		}

		versions.sort( function( a, b ){
			return a.version > b.version ? 1 : -1;
		} );

		return versions;
	}

	public boolean function versionIsDownloaded( required string version ) output=false {
		var versions = listDownloadedVersions();
		for( var v in versions ){
			if ( v.version == arguments.version ) {
				return true;
			}
		}

		return false;
	}

	public struct function listDownloadingVersions() output=false {
		return _getActiveDownloads();
	}

	public void function downloadVersion( required string version ) output=false {
		if ( _getActiveDownloads().keyExists( arguments.version ) ) {
			throw( type="UpdateManagerService.download.already.in.progress", message="Version [#arguments.version#] is already being downloaded" );
		}

		var versions = listAvailableVersions();
		for( var v in versions ){
			if ( v.version == arguments.version ) {
				var downloadUrl = _getRepositoryUrl() & "/" & v.path;

				return _downloadAndUnpackVersionAsynchronously( v.version, downloadUrl );
			}
		}

		throw( type="UpdateManagerService.unknown.version", message="Version [#arguments.version#] could not be found in the [#_getSetting( 'branch', 'release' )#] branch" );
	}

	public void function clearDownload( required string version ) output=false {
		var activeDownloads = listDownloadingVersions();

		activeDownloads.delete( arguments.version );
	}

	public boolean function downloadIsActive( required string version, required string downloadId ) output=false {
		var activeDownloads = listDownloadingVersions();

		return ( activeDownloads[ arguments.version ].id ?: "" ) == arguments.downloadId;
	}

	public boolean function downloadIsComplete( required string version ) output=false {
		var activeDownloads = listDownloadingVersions();

		return activeDownloads[ arguments.version ].complete ?: true;
	}

	public void function markDownloadAsErrored( required string version, required string downloadId, required struct error ) output=false {
		var activeDownloads = listDownloadingVersions();
		if ( ( activeDownloads[ arguments.version ].id ?: "" ) == arguments.downloadId ) {
			activeDownloads[ arguments.version ].complete = true;
			activeDownloads[ arguments.version ].success  = false;
			activeDownloads[ arguments.version ].error    = arguments.error;
		}
	}
	public void function markDownloadAsComplete( required string version, required string downloadId ) output=false {
		var activeDownloads = listDownloadingVersions();
		if ( ( activeDownloads[ arguments.version ].id ?: "" ) == arguments.downloadId ) {
			activeDownloads[ arguments.version ].complete = true;
			activeDownloads[ arguments.version ].success  = true;
		}
	}

	public boolean function installVersion( required string version ) output=false {
		var versions = listDownloadedVersions();
		for( var v in versions ){
			if ( v.version == arguments.version ) {
				try {
					admin action="updateMapping"
					      type     = "web"
					      virtual  = "/preside"
					      physical = v.path
					      archive  = ""
					      primary  = "physical"
					      trusted  = true
					      toplevel = false;

					_getApplicationReloadService().reloadAll();

					return true;
				} catch( "security" e ) {
					throw( type="UpdateManagerService.railo.admin.secured", message=e.message );
				}
			}
		}

		throw( type="UpdateManagerService.unknown.version", message="Version [#arguments.version#] could not be found locally" );
	}

	public boolean function deleteVersion( required string version ) output=false {
		if ( arguments.version == getCurrentVersion() ) {
			throw( type="UpdateManagerService.cannot.delete.current.version", message="You cannot delete the currently installed version, [#arguments.version#] from the server" );
		}
		var versions = listDownloadedVersions();
		for( var v in versions ){
			if ( v.version == arguments.version ) {
				try {
					DirectoryDelete( v.path, true );

					return true;
				} catch( any e ) {
					throw( type="UpdateManagerService.failed.to.delete", message=e.message );
				}
			}
		}

		throw( type="UpdateManagerService.unknown.version", message="Version [#arguments.version#] could not be found locally" );
	}

	public struct function getSettings() output=false {
		return _getSystemConfigurationService().getCategorySettings( category="updatemanager" );
	}

	public void function saveSettings( required struct settings ) output=false {
		var cfgService = _getSystemConfigurationService();

		for( var key in arguments.settings ) {
			cfgService.saveSetting( category="updatemanager", setting=key, value=arguments.settings[ key ] );
		}
	}

// private helpers
	private xml function _fetchS3BucketListing() output=false {
		return XmlParse( _getRepositoryUrl() );
	}

	private struct function _fetchVersionInfo( required string versionFilePath ) ouptut=false {
		var result = "";
		var versionFileUrl = ListAppend( _getRepositoryUrl(), arguments.versionFilePath, "/" );

		try {
			http url=versionFileUrl result="result" throwOnError=true;
			return DeSerializeJson( result.fileContent );
		} catch ( any e ) {
			return { version="unknown" };
		}
	}

	private string function _getRemoteBranchPath() output=false {
		var branch = _getSetting( setting="branch", default="release" );
		var path   = "presidecms/";

		switch( branch ) {
			case "bleedingEdge": return path & "bleeding-edge/";
			case "stable"      : return path & "stable/";
		}

		return path & "release/";
	}

	private string function _getSetting( required string setting, any default="" ) output=false {
		return _getSystemConfigurationService().getSetting( category="updatemanager", setting=arguments.setting, default=arguments.default );
	}

	private string function _getVersionContainerDirectory() output=false {
		var presideDirectory = _getPresidePath();
		return presideDirectory & "/../";
	}

	private void function _downloadAndUnpackVersionAsynchronously( required string version, required string downloadUrl ) output=false {
		var tempPath        = getTempDirectory() & "/" & CreateUUId() & ".zip";
		var downloadId      = CreateUUId();
		var activeDownloads = _getActiveDownloads();

		activeDownloads[ arguments.version ] = { complete=false, success=false, id=downloadId };

		thread name=downloadId downloadId=downloadId downloadUrl=arguments.downloadUrl unpackToDir=_getVersionContainerDirectory() downloadPath=tempPath updateManagerService=this version=arguments.version {
			try {
				http url=attributes.downloadUrl path=attributes.downloadPath throwOnError=true;
			} catch ( any e ) {
				attributes.updateManagerService.markDownloadAsErrored( attributes.version, attributes.downloadId, e );
				abort;
			}

			if ( attributes.updateManagerService.downloadIsActive( attributes.version, attributes.downloadId ) ) {
				try {
					zip action="unzip" file=attributes.downloadPath destination=attributes.unpackToDir;
				} catch( any e ) {
					attributes.updateManagerService.markDownloadAsErrored( attributes.version, attributes.downloadId, e );
					abort;
				}

				attributes.updateManagerService.markDownloadAsComplete( attributes.version, attributes.downloadId );
			}
		}
	}

// getters and setters
	private string function _getRepositoryUrl() output=false {
		return _repositoryUrl;
	}
	private void function _setRepositoryUrl( required string repositoryUrl ) output=false {
		_repositoryUrl = arguments.repositoryUrl;
	}

	private string function _getPresidePath() output=false {
		return _presidePath;
	}
	private void function _setPresidePath( required string presidePath ) output=false {
		_presidePath = arguments.presidePath;
	}

	private any function _getSystemConfigurationService() output=false {
		return _systemConfigurationService;
	}
	private void function _setSystemConfigurationService( required any systemConfigurationService ) output=false {
		_systemConfigurationService = arguments.systemConfigurationService;
	}

	private any function _getApplicationReloadService() output=false {
		return _applicationReloadService;
	}
	private void function _setApplicationReloadService( required any applicationReloadService ) output=false {
		_applicationReloadService = arguments.applicationReloadService;
	}

	private struct function _getActiveDownloads() output=false {
		return _activeDownloads;
	}
	private void function _setActiveDownloads( required struct activeDownloads ) output=false {
		_activeDownloads = arguments.activeDownloads;
	}

}