package
{
	public class StringUtil
	{
		private static var INT_STR:String = "%d"; 
		private static var FLOAT_STR:String = "%f"; 
		private static var STRING_STR:String = "%s"; 
		private static var BRACKET_STR:String = "{";
		
		public static function Format(string:String, ...args):String {
			
			for(var i:int = 0;i<args.length;i++){
				if(string.indexOf(BRACKET_STR)>0){
					string = string.replace(new RegExp("\\{" + i + "\\}", ""), args[i]);
				}
				else if(string.indexOf(INT_STR)>0){
					string = string.replace(new RegExp("\\d", ""), args[i]);
				}
				else if(string.indexOf(FLOAT_STR)>0){
					string = string.replace(new RegExp("\\f", ""), args[i]);
				}
				else if(string.indexOf(STRING_STR)>0){
					string = string.replace(new RegExp("\\s", ""), args[i]);
				}
			}
			return string;
		}
	}
}