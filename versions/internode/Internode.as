﻿import netusage.internode.InternodeNetUsageData;
import netusage.INetUsageData;
import netusage.Main;

import com.chumby.util.MCUtil;

class Internode
{
	//{ static constants
	private static var MC_WIDTH:Number = 320;
	private static var MC_HEIGHT:Number = 240;
	//}
	
	//-------------------------------------------------------------------
	// MTASC starts with this entry point
	public static function main()
	{
		//get chumby widget variables
		//note that variable names cannot be longer than 32 characters
		var username:String = _root["_private_netusage_inode_username"];
		var password:String = _root["_private_netusage_inode_password"];
		var accountName:String = _root["_private_netusage_inode_accname"];
		
		//validation done in INetUsageData
		
		//init INetUsageData interface
		var netUsageData:INetUsageData = new InternodeNetUsageData(username, password, accountName);
		
		//load UI
		var mainMC:MovieClip = MCUtil.CreateWithClass(Main, _root, "main", 1, {}, [netUsageData]);
	}
}