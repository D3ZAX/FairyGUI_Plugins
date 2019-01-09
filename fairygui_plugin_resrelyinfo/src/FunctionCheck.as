package
{
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import fairygui.editor.plugin.IEditorUIPackage;
	import fairygui.editor.plugin.IFairyGUIEditor;

	public class FunctionCheck
	{
		private var _editor: IFairyGUIEditor;
		private var _pluginLogger: PluginLogger;
		
		public function FunctionCheck(editor: IFairyGUIEditor, pluginLogger: PluginLogger) {
			this._editor = editor;
			this._pluginLogger = pluginLogger;
		}
		
		public function CheckFlip(): void {
			var packageIdToData: Dictionary = new Dictionary();
			var comInfoDic: Dictionary = new Dictionary();
			
			var noFlip: Boolean = true;
			
			var packageDirs: Array = FileTool.getSubFolders(_editor.project.basePath + File.separator + "assets");
			for each (var packageDir: File in packageDirs) {
				var packageData: IEditorUIPackage = _editor.getPackage(packageDir.name);
				
				packageIdToData[packageData.id] = packageData;
				
				var packageXML:XML = new XML(FileTool.readFile(packageDir.nativePath + File.separator + "package.xml"));
				var resourceListXML:XMLList = packageXML.child("resources").children();
				var exported: XMLList;
				for each (var item:XML in resourceListXML) {
					switch(item.name().toString()) {
						case "component":
							var componentInfo: Object = new Object();
							componentInfo.path = packageDir.nativePath + item.attribute("path").toString() + item.attribute("name").toString();
							var name: String = item.attribute("name").toString();
							componentInfo.name = name.substr(0, name.lastIndexOf("."));
							componentInfo.id = item.attribute("id").toString();
							componentInfo.packageId = packageData.id;
							
							comInfoDic[packageData.id + componentInfo.id] = componentInfo;
							break;
					}
				}
			}
			
			for each (var compInfo: Object in comInfoDic) {
				var componentXML:XML = new XML(FileTool.readFile(compInfo.path));
				var displayListXMLList:XMLList = componentXML.child("displayList").children();
				
				for each (item in displayListXMLList) {
					// log
					if (item.@flip != undefined) {
						if (noFlip) {
							this._pluginLogger.warningInfos.push("设置了翻转功能的控件：");
						}
						this._pluginLogger.warningInfos.push("包: " + packageIdToData[compInfo.packageId].name
							+ " 组件: " + compInfo.name
							+ " 控件: " + item.attribute("name").toString());
						noFlip = false;
					}
				}
			}
			
			if (noFlip) {
				this._pluginLogger.warningInfos.push("没有控件使用翻转功能！");
			}
			_pluginLogger.checkWarningAndLog();
		}
	}
}