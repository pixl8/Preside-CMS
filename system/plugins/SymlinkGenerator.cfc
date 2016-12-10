component extends="coldbox.system.Plugin" output="false" singleton="true" {

	public any function init( controller ) output=false {
		super.init( arguments.controller );

		setpluginName("Symlink Generator");
		setpluginVersion("1.0");
		setpluginDescription("Provides a OS agnostic method for creating symlinks from your ColdBox application");
		setPluginAuthor("Pixl8 Interactive");
		setPluginAuthorURL("www.pixl8.co.uk");

		return this;
	}

	public void function symLink( required string source, required string target, boolean directory=true ) output=false {
		var command = "";
		var args    = "";

		if ( arguments.directory ? DirectoryExists( arguments.target ) : FileExists( arguments.target ) ) {
			return;
		}

		if ( ( server.os.name ?: "" ) contains "windows" ) {
			command = "cmd.exe";
			args    = "/c mklink /D /J ""#arguments.target#"" ""#arguments.source#""";
		} else {
			command = "ln";
			args    = "-s ""#arguments.source#"" ""#arguments.target#""";
		}

		execute name="#command#" arguments="#args#" timeout="10" variable="output" errorVariable="e";
	}
}