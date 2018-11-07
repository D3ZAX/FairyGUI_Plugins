package 
{
	import flash.events.Event;
	import flash.filesystem.File;
	
	import fairygui.PopupMenu;
	import fairygui.editor.plugin.ICallback;
	import fairygui.editor.plugin.IFairyGUIEditor;
	import fairygui.editor.plugin.IPublishData;

	/**
	 * 插件入口类，名字必须为PlugInMain。每个项目打开都会创建一个新的PlugInMain实例，并传入当前的编辑器句柄；
	 * 项目关闭时dispose被调用，可以在这里处理一些清理的工作（如果有）。
	 */
	public class PlugInMain
	{
		private var _editor:IFairyGUIEditor;
		private var _relyTreeExporter:ExportRelyTree;
		private var _pluginLogger: PluginLogger;
		
		
		
		public function PlugInMain(editor:IFairyGUIEditor)
		{
			_editor = editor;
			
//			if(_editor.project.type=="Starling" || _editor.project.type=="Flash")
//			{
//				_editor.registerPublishHandler(new ExportNoZipPlugIn(_editor));
////				_editor.registerPublishHandler(new GenerateCodePlugIn(_editor));
//				_editor.registerPublishHandler(new AutoGenerateCodePlugin(_editor));
//				_editor.registerPublishHandler(new BatExecutePlugin(_editor));
//			}
			
//			_editor.registerComponentExtension("窗口", "MyWindowClass", null);
			
//			_editor.menuBar.getMenu("tool").addItem("测试", onClickSet);
			
			_pluginLogger = new PluginLogger(editor);
			
			
			_relyTreeExporter = new ExportRelyTree(editor, _pluginLogger);
			
			_editor.registerPublishHandler(_relyTreeExporter);
			
			
			_editor.registerPublishHandler(_pluginLogger);
			
			_editor.menuBar.addMenu("export_tool", "导出工具", new PopupMenu(), "help");
			_editor.menuBar.getMenu("export_tool").addItem("导出依赖关系表", onClickExportRelyTree);
		}
		
		private function onClickSet(evt:Event): void
		{
			_editor.alert("Hello world!");
		}
		
		private function onClickExportRelyTree(evt:Event): void
		{
			_relyTreeExporter.tryExportRelyInfo();
			_pluginLogger.checkWarningAndLog();
		}
		
		public function dispose():void
		{
		}
	}
}