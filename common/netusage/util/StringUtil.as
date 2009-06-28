/**
 * Convenient methods for dealing with strings.
 * 
 * @author Samuel Lai
 */
class netusage.util.StringUtil 
{
	public static function isNullOrEmpty(s:String):Boolean
	{
		if (s == null || s.length == 0)
			return true;
		else
			return false;
	}
	
}