package {
	import flash.filesystem.File;
	
	import fairygui.editor.plugin.ICallback;
	import fairygui.editor.plugin.IFairyGUIEditor;
	import fairygui.editor.plugin.IPublishData;
	import fairygui.editor.plugin.IPublishHandler;

	public class PluginLogger implements IPublishHandler {
		private var _editor:IFairyGUIEditor;

		private var _warningInfos: Array = new Array();
		private var _logInfos: Array = new Array();
		
		public function get warningInfos(): Array {
			return this._warningInfos;
		}
		
		public function get logInfos(): Array {
			return this._logInfos;
		}

		public function PluginLogger(editor:IFairyGUIEditor) {
			_editor = editor;
		}
		
		public function doExport(data:IPublishData, callback:ICallback): Boolean {
			this.checkWarningAndLog(true);
			callback.callOnSuccess();
			return true;
		}
		
		public function logFile(logMsg: Array): void {
			var publishJson: Object = JSON.parse(FileTool.readFile(_editor.project.basePath + File.separator + "settings" + File.separator + "Publish.json"));
			
			var publishPath: String = publishJson.path;
			
			FileTool.writeFile(publishPath + File.separator + "log" + ".txt", logMsg.join("\n"));
		}
		
		public function checkWarningAndLog(noSuccessTip: Boolean = false): void {
			if (this._logInfos.length > 0) {
				logFile(this._logInfos);
			}
			
			if (this._warningInfos.length > 0) {
				_editor.alert(this._warningInfos.join("\n"));
			} else if (!noSuccessTip) {
				_editor.alert("导出成功！");
			}
			
			this._logInfos.splice(0, this._logInfos.length);
			this._warningInfos.splice(0, this._warningInfos.length);
		}
	}
}