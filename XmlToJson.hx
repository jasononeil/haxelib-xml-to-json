import haxe.Json;

#if neko 
	import sys.FileSystem;
	import sys.io.File;
	import Sys.println;
#end

using StringTools;

class XmlToJson 
{
	#if neko
		static function main()
		{
			var cwd = Sys.getCwd();
			var xmlFile = cwd + "haxelib.xml";
			var jsonFile = cwd + "haxelib.json";

			if (!FileSystem.exists(xmlFile))
			{
				println('File haxelib.xml was not found in the current directory.');
				Sys.exit(0);
			}

			var xmlString = File.getContent(xmlFile);
			var json = convert(xmlString);
			var jsonString = prettyPrint(json);

			println("START");
			println("-----");
			println(jsonString);
			println("-----");
			println("END");

			File.saveContent(jsonFile, jsonString);
			println('Saved to $jsonFile');
		}
	#end

	#if js 
		static inline function jQ(input:Dynamic) return new js.JQuery(input);
		static function main()
		{
			jQ(function () {
				var xmlTA = jQ("#xml");
				var jsonTA = jQ("#json");
				var convertBtn = jQ("#convert");
				
				xmlTA.text(sampleXml);
				
				convertBtn.click(function (e) {
					var json = convert(xmlTA.val());
					jsonTA.text(prettyPrint(json));
				});

				jQ("textarea").focus(function (e) {
					js.JQuery.cur.select();
					return false;
				});

			});
		}
	#end 


	static function convert(inXml:String)
	{
		// Set up the default JSON structure

		var json = {
			"name": "",
			"url" : "",
			"license": "",
			"tags": [],
			"description": "",
			"version": "0.0.1",
			"releasenote": "",
			"contributors": [],
			"dependencies": {}
		};

		// Parse the XML and set the JSON

		var xml = Xml.parse(inXml);
		var project = xml.firstChild();
		json.name = project.get("name");
		json.license = project.get("license");
		json.url = project.get("url");
		for (node in project)
		{
			switch (node.nodeType)
			{
				case Xml.Element:
					switch (node.nodeName)
					{
						case "tag": 
							json.tags.push(node.get("v"));
						case "user":
							json.contributors.push(node.get("name"));
						case "version":
							json.version = node.get("name");
							json.releasenote = node.firstChild().toString();
						case "description":
							json.description = node.firstChild().toString();
						case "depends":
							var name = node.get("name");
							var version = node.get("version");
							if (version == null) version = "";
							Reflect.setField(json.dependencies, name, version);
						default: 
					}
				default: 
			}
		}

		return json;
	}

	static function prettyPrint(json:Dynamic, indent="")
	{
		var sb = new StringBuf();
		sb.add("{\n");

		var firstRun = true;
		for (f in Reflect.fields(json))
		{
			if (!firstRun) sb.add(",\n");
			firstRun = false;

			var value = switch (f) {
				case "dependencies":
					var d = Reflect.field(json, f);
					prettyPrint(d, indent + "  ");
				default: 
					Json.stringify(Reflect.field(json, f));
			}
			sb.add(indent+'  "$f": $value');
		}

		sb.add('\n$indent}');
		return sb.toString();
	}

	static var sampleXml = '<project name="detox" url="https://github.com/jasononeil/detox" license="MIT">
	<user name="jason"/>
	<tag v="js" />
	<tag v="dom" />
	<tag v="jquery" />
	<tag v="xml" />
	<tag v="domtools" />
	<tag v="dtx" />
	<tag v="detox" />
	<description>Detox (previously called DOMTools) - A cross-target library for Haxe to make working with Xml and the DOM easy... not dissimilar from jQuery etc but works wherever Haxe works.</description>
	<version name="0.8.0.0">Rename to detox, working on JS (client), Neko, CPP and Flash9+.  Major additions to Widgets, (more to come), more fixes and unit tests</version>
	<depends name="xirsys_stdjs"/>
	<depends name="tink_macros"/>
	<depends name="beanhx" version="1.0" />
	<depends name="selecthxml"/>
</project>
';
}