/**
 * Properties that inform the build about where to get things, etc.
 *
 * @accessors true
 */
component accessors=true {
	cwd     = GetDirectoryFromPath( GetCurrentTemplatePath() );
	docsDir = ExpandPath( "/docs/" );

	property name="editSourceLink"       default="https://github.com/pixl8/Preside-CMS/blob/stable/support/docs{path}";
	property name="dashBuildNumber"      default="1.0.0";
	property name="dashDownloadUrl"      default="http://docs.presidecms.com/dash/presidecms.tgz";
}