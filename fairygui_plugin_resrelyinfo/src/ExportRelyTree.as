package {
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import fairygui.editor.plugin.IEditorUIPackage;
	import fairygui.editor.plugin.IFairyGUIEditor;

	public class ExportRelyTree {
		private var _editor: IFairyGUIEditor;
		
		public function ExportRelyTree(editor:IFairyGUIEditor) {
			_editor = editor;
		}
		
		public function exportRelyInfo(): void {
			var packageIdToData: Dictionary = new Dictionary();
			var comInfoDic: Dictionary = new Dictionary();
			var txInfoDic: Dictionary = new Dictionary();
			
			var comRelyDic: Object = new Object();
			
			var warningInfos: Array = new Array(); 
			
			var packageDirs: Array = FileTool.getSubFolders(_editor.project.basePath + File.separator + "assets");

			for each (var packageDir: File in packageDirs) {
				var packageData: IEditorUIPackage = _editor.getPackage(packageDir.name);
				
				packageIdToData[packageData.id] = packageData;
				
				var packageXML:XML = new XML(FileTool.readFile(packageDir.nativePath + File.separator + "package.xml"));
				var resourceListXML:XMLList = packageXML.child("resources").children();
				
				for each (var item:XML in resourceListXML) {
					switch(item.name().toString()) {
						case "component":
							var componentInfo: Object = {};
							componentInfo.path = packageDir.nativePath + item.attribute("path").toString() + item.attribute("name").toString();
							var name: String = item.attribute("name").toString();
							componentInfo.name = name.substr(0, name.lastIndexOf("."));
							componentInfo.packageId = packageData.id;
							var exportedC: XMLList = item.attribute("exported");
							if (exportedC) {
								componentInfo.export = exportedC.toString() === "true";
							} else {
								componentInfo.export = false;
							}
							
							comInfoDic[item.attribute("id").toString()] = componentInfo;
							break;
						case "image":
							var textureInfo: Object = {};
							textureInfo.name = item.attribute("name").toString();
							textureInfo.packageId = packageData.id;
							textureInfo.atlas = item.attribute("atlas").toString();
							var exportedT: XMLList = item.attribute("exported");
							if (exportedT) {
								textureInfo.export = exportedT.toString() === "true";
							} else {
								textureInfo.export = false;
							}
							
							txInfoDic[item.attribute("id").toString()] = textureInfo;
							break;
					}
				}
			}
			
			for each (var compInfo: Object in comInfoDic) {
				recursionToSetRelyTreeOfComponent(compInfo, comInfoDic, txInfoDic, packageIdToData, comRelyDic, warningInfos);
			}
			
			for each (var exportObj: Object in comRelyDic) {
				exportObj.needpack = new Array();
				for (var packageId: String in exportObj.dicPackage) {
					exportObj.needpack.push(packageIdToData[packageId].name);
				}
				delete exportObj.dicPackage;
				
				exportObj.atlas = new Array();
				var textureAtlas: Dictionary = new Dictionary();
				for (var textureId: String in exportObj.dicTexture) {
					textureAtlas[getTextureResKey(packageIdToData[txInfoDic[textureId].packageId].name, textureId, txInfoDic[textureId].atlas)] = true;
				}
				for (var atlas: String in textureAtlas) {
					exportObj.atlas.push(atlas);
				}
				delete exportObj.dicTexture;
			}
			
			var publishJson: Object = JSON.parse(FileTool.readFile(_editor.project.basePath + File.separator + "settings" + File.separator + "Publish.json"));
			
			var publishPath: String = publishJson.path;
			
			FileTool.writeFile(publishPath + File.separator + "ui_info" + ".json", JSON.stringify(comRelyDic));
			
			if (warningInfos.length > 0) {
				_editor.alert(warningInfos.join("\n"));
			} else {
				_editor.alert("导出成功！");
			}
			
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
		
		public function recursionToSetRelyTreeOfComponent(componentInfo: Object, comInfoDic: Dictionary, txInfoDic: Dictionary, packageIdToData: Dictionary, comRelyDic: Object, warningInfos: Array): void {
			if (!comRelyDic[componentInfo.name]) {
				var exportObj: Object = new Object();
				exportObj.dicTexture = new Object();
				exportObj.dicPackage = new Object();
				exportObj.dicPackage[componentInfo.packageId] = true;
				
				exportObj.pack = packageIdToData[componentInfo.packageId].name;
				
				var componentXML:XML = new XML(FileTool.readFile(componentInfo.path));
				var displayListXMLList:XMLList = componentXML.child("displayList").children();
				
				for each (var item:XML in displayListXMLList) {
					switch (item.name().toString()) {
						case "image":
							var textureId: String = item.attribute("src").toString()
							exportObj.dicTexture[textureId] = true;
							exportObj.dicPackage[txInfoDic[textureId].packageId] = true;
							if (componentInfo.export && !txInfoDic[textureId].export) {
								warningInfos.push(StringUtil.Format("Warnning: Image \"{0}\" in Package \"{1}\" relyed by Component \"{2}\" in Package \"{3}\" is not set to export!", txInfoDic[textureId].name, packageIdToData[txInfoDic[textureId].packageId].name, componentInfo.name, packageIdToData[componentInfo.packageId].name));
							}
							break;
						case "loader":
							var urlXMLList: XMLList = item.attribute("url");
							if (urlXMLList) {
								var url: String = urlXMLList.toString();
								for (var packId: String in packageIdToData) {
									var startIndex: int = 5;
									if (url.indexOf(packId) === startIndex) {
										var resId: String = url.substr(startIndex + packId.length);
										if (comInfoDic[resId] && comInfoDic[resId].packageId === packId) {
											recursionToSetRelyTreeOfComponent(comInfoDic[resId], comInfoDic, txInfoDic, packageIdToData, comRelyDic, warningInfos);
											for (var packageId: String in comRelyDic[comInfoDic[resId].name].dicPackage) {
												exportObj.dicPackage[packageId] = true;
											}
											for (var texId: String in comRelyDic[comInfoDic[resId].name].dicTexture) {
												exportObj.dicTexture[texId] = true;
											}
											if (componentInfo.export && !comInfoDic[resId].export) {
												warningInfos.push(StringUtil.Format("Warnning: Component \"{0}\" in Package \"{1}\" relyed by Component \"{2}\" in Package \"{3}\" is not set to export!", comInfoDic[resId].name, packageIdToData[comInfoDic[resId].packageId].name, componentInfo.name, packageIdToData[componentInfo.packageId].name));
											}
											break;
										} else if (txInfoDic[resId] && txInfoDic[resId].packageId === packId) {
											exportObj.dicTexture[resId] = true;
											exportObj.dicPackage[txInfoDic[resId].packageId] = true;
											
											if (componentInfo.export && !txInfoDic[resId].export) {
												warningInfos.push(StringUtil.Format("Warnning: Image \"{0}\" in Package \"{1}\" relyed by Component \"{2}\" in Package \"{3}\" is not set to export!", txInfoDic[resId].name, packageIdToData[txInfoDic[resId].packageId].name, componentInfo.name, packageIdToData[componentInfo.packageId].name));
											}
	
											break;
										}
									}
								}
							}
							break;
						case "component":
							var comId: String = item.attribute("src").toString();
							recursionToSetRelyTreeOfComponent(comInfoDic[comId], comInfoDic, txInfoDic, packageIdToData, comRelyDic, warningInfos);
							for (var pId: String in comRelyDic[comInfoDic[comId].name].dicPackage) {
								exportObj.dicPackage[pId] = true;
							}
							for (var tId: String in comRelyDic[comInfoDic[comId].name].dicTexture) {
								exportObj.dicTexture[tId] = true;
							}
							if (componentInfo.export && !comInfoDic[comId].export) {
								warningInfos.push(StringUtil.Format("Warnning: Component \"{0}\" in Package \"{1}\" relyed by Component \"{2}\" in Package \"{3}\" is not set to export!", comInfoDic[comId].name, packageIdToData[comInfoDic[comId].packageId].name, componentInfo.name, packageIdToData[componentInfo.packageId].name));
							}
							break;
					}
				}
				comRelyDic[componentInfo.name] = exportObj;
			}
		}
		
		public function getTextureResKey(packageName: String, textureId: String, atlas: String): String {
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
	}
}