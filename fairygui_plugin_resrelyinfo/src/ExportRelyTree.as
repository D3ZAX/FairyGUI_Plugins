package {
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import fairygui.editor.plugin.ICallback;
	import fairygui.editor.plugin.IEditorUIPackage;
	import fairygui.editor.plugin.IFairyGUIEditor;
	import fairygui.editor.plugin.IPublishData;
	import fairygui.editor.plugin.IPublishHandler;

	public class ExportRelyTree implements IPublishHandler{
		private var _editor: IFairyGUIEditor;
		private var _pluginLogger: PluginLogger;
		private var _lastRunningFunc: String;
		private var _lastOperate: String;
		private var _lastVisitPack: String;
		private var _lastVisitCom: String;
		private var _lastVisitComType: String;
		
		public function ExportRelyTree(editor: IFairyGUIEditor, pluginLogger: PluginLogger) {
			_editor = editor;
			this._pluginLogger = pluginLogger;
		}
		
		public function tryExportRelyInfo(): Boolean {
			try {
				exportRelyInfo();
				return true;
			} catch (e: Error) {
				this._pluginLogger.warningInfos.splice(0, 0, e.message);
				if (this._lastRunningFunc) {
					this.logWarning("最后运行的方法（程序）: " + this._lastRunningFunc);
				}
				if (this._lastOperate) {
					this.logWarning("最后的操作（程序）: " + this._lastOperate);
				}
				if (this._lastVisitPack) {
					this.logWarning("最后访问的包名（极有可能出错）: " + this._lastVisitPack);
				}
				if (this._lastVisitCom) {
					this.logWarning("最后访问的组件名（极有可能出错）: " + this._lastVisitCom);
				}
				if (this._lastVisitComType) {
					this.logWarning("最后访问的组件类型: " + this._lastVisitComType);
				}
				return false;
			}
			return false;
		}
		
		public function exportRelyInfo(): void {
			this._lastRunningFunc = "exportRelyInfo()";
			this._lastVisitPack = null;
			this._lastVisitComType = null;
			this._lastVisitCom = null;

			var packageIdToData: Dictionary = new Dictionary();
			var comInfoDic: Dictionary = new Dictionary();
			var txInfoDic: Dictionary = new Dictionary();
			var soundInfoDic: Dictionary = new Dictionary();
			var comSounds: Array = new Array();
			
			var comRelyDic: Object = new Object();
			var comRes: Object = {
				sound: []
			};
			var exportDic: Object = {
				rely: comRelyDic,
				common: comRes
			};
			
			// Read and record commmon res
			this._lastOperate = "Read and record commmon res";
			var comSettings: Object = JSON.parse(FileTool.readFile(_editor.project.basePath + File.separator + "settings/Common.json"));
			if (comSettings.buttonClickSound != "") {
				comSounds.push(comSettings.buttonClickSound);
			}


			// Read and record ui rely tree
			// Read package ui info
			this._lastOperate = "Read package ui info";
			var comNameDic: Dictionary = new Dictionary();
			var packageDirs: Array = FileTool.getSubFolders(_editor.project.basePath + File.separator + "assets");
			for each (var packageDir: File in packageDirs) {
				this._lastVisitPack = packageDir.name;
				var packageData: IEditorUIPackage = _editor.getPackage(packageDir.name);
				
				packageIdToData[packageData.id] = packageData;
				
				var packageXML:XML = new XML(FileTool.readFile(packageDir.nativePath + File.separator + "package.xml"));
				var resourceListXML:XMLList = packageXML.child("resources").children();
				var exported: XMLList;
				for each (var item:XML in resourceListXML) {
					switch(item.name().toString()) {
						case "component":
							this._lastVisitComType = "component";
							this._lastVisitCom = item.attribute("name").toString();
							if (comNameDic[this._lastVisitCom]) {
								this.logWarning("Component: " + this._lastVisitCom + " in Package: " + this._lastVisitPack + " repeated, this may cause error!");
							}
							comNameDic[this._lastVisitCom] = true;
							var componentInfo: Object = new Object();
							componentInfo.path = packageDir.nativePath + item.attribute("path").toString() + item.attribute("name").toString();
							var name: String = item.attribute("name").toString();
							componentInfo.name = name.substr(0, name.lastIndexOf("."));
							componentInfo.id = item.attribute("id").toString();
							componentInfo.packageId = packageData.id;
							exported = item.attribute("exported");
							if (exported) {
								componentInfo.export = exported.toString() === "true";
							} else {
								componentInfo.export = false;
							}
							
							comInfoDic[packageData.id + componentInfo.id] = componentInfo;
							break;
						case "image":
							this._lastVisitComType = "image";
							this._lastVisitCom = item.attribute("name").toString();
							var textureInfo: Object = {};
							textureInfo.name = item.attribute("name").toString();
							textureInfo.packageId = packageData.id;
							textureInfo.atlas = item.attribute("atlas").toString();
							textureInfo.id = item.attribute("id").toString();
							exported = item.attribute("exported");
							if (exported) {
								textureInfo.export = exported.toString() === "true";
							} else {
								textureInfo.export = false;
							}
							
							txInfoDic[packageData.id + textureInfo.id] = textureInfo;
							break;
						case "sound":
							this._lastVisitComType = "sound";
							this._lastVisitCom = item.attribute("name").toString();
							var soundInfo: Object = {};
							soundInfo.name = item.attribute("name").toString();
							soundInfo.packageId = packageData.id;
							soundInfo.id = item.attribute("id").toString();
							exported = item.attribute("exported");
							if (exported) {
								soundInfo.export = exported.toString() === "true";
							} else {
								soundInfo.export = false;
							}
							
							soundInfoDic[packageData.id + soundInfo.id] = soundInfo;
							break;
					}
				}
			}
			
			// Read single component rely info and record rely info
			this._lastOperate = "Read single component rely info and record rely info";
			for each (var compInfo: Object in comInfoDic) {
				recursionToSetRelyTreeOfComponent(compInfo, comInfoDic, txInfoDic, packageIdToData, comRelyDic);
			}
			this._lastRunningFunc = "exportRelyInfo()";
			this._lastVisitPack = null
			this._lastVisitComType = null;
			this._lastVisitCom = null;
			
			// Sort rely info
			this._lastOperate = "Sort rely info";
			for each (var exportObj: Object in comRelyDic) {
				// package
				var temArr: Array = new Array();
				for (var packageId: String in exportObj.dicPackage) {
					temArr.push(packageIdToData[packageId].name);
				}
				if (temArr.length > 0) {
					exportObj.needpack = temArr;
					temArr = new Array();
				}
				delete exportObj.dicPackage;
				
				// texture
				var textureAtlas: Dictionary = new Dictionary();
				for (var textureId: String in exportObj.dicTexture) {
					textureAtlas[getTextureResKey(packageIdToData[txInfoDic[textureId].packageId].name, txInfoDic[textureId].id, txInfoDic[textureId].atlas)] = true;
					this._lastRunningFunc = "exportRelyInfo()";
				}
				for (var atlas: String in textureAtlas) {
					temArr.push(atlas);
				}
				if (temArr.length > 0) {
					exportObj.atlas = temArr;
					temArr = new Array();
				}
				delete exportObj.dicTexture;
				
				// sound
				for (var soundId: String in exportObj.dicSound) {
					if (comSounds.indexOf(soundId) < 0) {
						temArr.push(this.getSoundResKey(soundId, packageIdToData, soundInfoDic));
						this._lastRunningFunc = "exportRelyInfo()";
					}
				}
				if (temArr.length > 0) {
					exportObj.sound = temArr;
					temArr = new Array();
				}
				delete exportObj.dicSound;
			}
			
			// Deal with common res
			this._lastOperate = "Deal with common res";
			for each (var sound: String in comSounds) {
				// sound
				comRes.sound.push(this.getSoundResKey(sound, packageIdToData, soundInfoDic));
				this._lastRunningFunc = "exportRelyInfo()";
			}
			
			var publishJson: Object = JSON.parse(FileTool.readFile(_editor.project.basePath + File.separator + "settings" + File.separator + "Publish.json"));
			
			var publishPath: String = publishJson.path;
			
			FileTool.writeFile(publishPath + File.separator + "ui_info" + ".json", JSON.stringify(exportDic));

//			var projectXML:XML = new XML(FileTool.readFile(_editor.project.basePath + File.separator + "project.xml"));
//			for each (var j:XML in (projectXML.packages as XMLList).children()) 
//			{
//				var publishPath:String = _editor.project.basePath + File.separator + j.@name;
//				var packageXML:XML = new XML(FileTool.readFile(publishPath + File.separator + "package.xml"));
//				
//				var publishPackageName:String = PinYinUtils.toPinyin(packageXML.publish.@name);
//				
//				for each (var i:XML in (packageXML.resources as XMLList).children())
//				{
//					packageObjByGid[String(i.@id)] = i;
//					packageObjByClassName[String(i.@name)] = {xml:i, packageName:String(j.@name)};
//				}
//			}
		}
		
		public function recursionToSetRelyTreeOfComponent(componentInfo: Object, comInfoDic: Dictionary, txInfoDic: Dictionary, packageIdToData: Dictionary, comRelyDic: Object): void {
			this._lastRunningFunc = "recursionToSetRelyTreeOfComponent()";
			this._lastVisitComType = "component";
			this._lastVisitCom = componentInfo.name;
			this._lastVisitPack = packageIdToData[componentInfo.packageId].name;
			if (!comRelyDic[componentInfo.name]) {
				var exportObj: Object = new Object();
				exportObj.dicTexture = new Object();
				exportObj.dicSound = new Object();
				exportObj.dicPackage = new Object();
				exportObj.dicPackage[componentInfo.packageId] = true;
				
				exportObj.pack = packageIdToData[componentInfo.packageId].name;
				
				var componentXML:XML = new XML(FileTool.readFile(componentInfo.path));
				var displayListXMLList:XMLList = componentXML.child("displayList").children();

				for each (var item:XML in displayListXMLList) {
					switch (item.name().toString()) {
						case "image":
							var textureId: String = (item.@pkg != undefined ? item.attribute("pkg").toString() : componentInfo.packageId) + item.attribute("src").toString();
							// log
							this._lastVisitComType = "image";
							this._lastVisitCom = txInfoDic[textureId].name;
							this._lastVisitPack = packageIdToData[txInfoDic[textureId].packageId].name;
							
							exportObj.dicTexture[textureId] = true;
							exportObj.dicPackage[txInfoDic[textureId].packageId] = true;
							if (componentInfo.export && !txInfoDic[textureId].export) {
								this.logWarning(StringUtil.Format("Warnning: Image \"{0}\" in Package \"{1}\" relyed by Component \"{2}\" in Package \"{3}\" is not set to export!", txInfoDic[textureId].name, packageIdToData[txInfoDic[textureId].packageId].name, componentInfo.name, packageIdToData[componentInfo.packageId].name));
							}
							break;
						case "loader":
						case "list":
							var attrName: String;
							switch (item.name().toString()) {
								case "loader":
									attrName = "url";
									break;
								case "list":
									attrName = "defaultItem";
									break;
							}
							var urlXMLList: XMLList = item.attribute(attrName);
							if (urlXMLList) {
								var url: String = urlXMLList.toString();
								var startIndex: int = 5;
								var resId: String = url.substr(startIndex);
								if (comInfoDic[resId]) {
									recursionToSetRelyTreeOfComponent(comInfoDic[resId], comInfoDic, txInfoDic, packageIdToData, comRelyDic);
									for (var packageId: String in comRelyDic[comInfoDic[resId].name].dicPackage) {
										exportObj.dicPackage[packageId] = true;
									}
									for (var texId: String in comRelyDic[comInfoDic[resId].name].dicTexture) {
										exportObj.dicTexture[texId] = true;
									}
									if (componentInfo.export && !comInfoDic[resId].export) {
										this.logWarning(StringUtil.Format("Warnning: Component \"{0}\" in Package \"{1}\" relyed by Component \"{2}\" in Package \"{3}\" is not set to export!", comInfoDic[resId].name, packageIdToData[comInfoDic[resId].packageId].name, componentInfo.name, packageIdToData[componentInfo.packageId].name));
									}
									break;
								} else if (txInfoDic[resId]) {
									// log
									this._lastVisitComType = "image";
									this._lastVisitCom = txInfoDic[resId].name;
									this._lastVisitPack = packageIdToData[txInfoDic[resId].packageId].name;
									
									exportObj.dicTexture[resId] = true;
									exportObj.dicPackage[txInfoDic[resId].packageId] = true;
									
									if (componentInfo.export && !txInfoDic[resId].export) {
										this.logWarning(StringUtil.Format("Warnning: Image \"{0}\" in Package \"{1}\" relyed by Component \"{2}\" in Package \"{3}\" is not set to export!", txInfoDic[resId].name, packageIdToData[txInfoDic[resId].packageId].name, componentInfo.name, packageIdToData[componentInfo.packageId].name));
									}
									
									break;
								}
							}
							break;
						case "component":
							var comId: String = (item.@pkg != undefined ? item.attribute("pkg").toString() : componentInfo.packageId) + item.attribute("src").toString();
							recursionToSetRelyTreeOfComponent(comInfoDic[comId], comInfoDic, txInfoDic, packageIdToData, comRelyDic);
							for (var pId: String in comRelyDic[comInfoDic[comId].name].dicPackage) {
								exportObj.dicPackage[pId] = true;
							}
							for (var tId: String in comRelyDic[comInfoDic[comId].name].dicTexture) {
								exportObj.dicTexture[tId] = true;
							}
							for (var sId: String in comRelyDic[comInfoDic[comId].name].dicSound) {
								exportObj.dicSound[sId] = true;
							}
							
							var buttons: XMLList = item.child("Button");
							for each (var button:XML in buttons) {
								if (button.@sound != undefined) {
									exportObj.dicSound[button.attribute("sound").toString()] = true;
								}
							}
							
							if (componentInfo.export && !comInfoDic[comId].export) {
								this.logWarning(StringUtil.Format("Warnning: Component \"{0}\" in Package \"{1}\" relyed by Component \"{2}\" in Package \"{3}\" is not set to export!", comInfoDic[comId].name, packageIdToData[comInfoDic[comId].packageId].name, componentInfo.name, packageIdToData[componentInfo.packageId].name));
							}
							break;
					}
				}
				comRelyDic[componentInfo.name] = exportObj;
			}
		}
		
		public function getTextureResKey(packageName: String, textureId: String, atlas: String): String {
			this._lastRunningFunc = "getTextureResKey()";
			if (!atlas) {
				atlas = "0";
			}
			switch (_editor.project.type) {
				case "egret":
					if (atlas === "alone") {
						return packageName + "@atlas_" + textureId;
					} else {
						return packageName + "@atlas" + atlas;
					}
					break;
			}
			
			if (atlas === "alone") {
				return packageName + "@atlas_" + textureId;
			} else {
				return packageName + "@atlas" + atlas;
			}
		}
		
		public function getSoundResKey(sound: String, packageIdToData: Dictionary, soundInfoDic: Dictionary): String {
			this._lastRunningFunc = "getSoundResKey()";
			var soundInfo: Object;
			switch (_editor.project.type) {
				case "egret":
					soundInfo = soundInfoDic[sound.substr(5)];
					return packageIdToData[soundInfo.packageId].name + "@" + soundInfo.id;
				default:
					soundInfo = soundInfoDic[sound.substr(5)];
					return packageIdToData[soundInfo.packageId].name + "@" + soundInfo.id;
			}
		}
		
		public function doExport(data:IPublishData, callback:ICallback): Boolean {
			if (this.tryExportRelyInfo()) {
				callback.callOnSuccess();
			} else {
				callback.addMsg(this._pluginLogger.getWarningInfo());
				callback.callOnFail();
			}
			return true;
		}
		
		private function logFile(str: String): void {
			this._pluginLogger.logInfos.push(str);
		}
		
		private function logWarning(str: String): void {
			this._pluginLogger.warningInfos.push(str);
		}
	}
}