/**
 * ...
 * @author Samuel Lai
 */
import netusage.INetUsageData;
import netusage.util.StringUtil;

import com.chumby.util.xml.XmlUtil;
import com.chumby.util.Delegate;
 
class netusage.internode.InternodeNetUsageData implements INetUsageData
{
	//{ constants
	private var UPDATE_INTERVAL:Number = 60000 * 30; //30 minutes
	//}
	
	//{ instance variables
	private var _hasStarted:Boolean;
	
	private var _username:String;
	private var _password:String;
	private var _accountName:String;
	
	private var _rolloverDate:Date;
	
	private var _peakDataUsed:Number;
	private var _peakDataQuota:Number;
	private var _peakExcessCost:Number;
	
	private var _onError:Function;
	private var _onUpdated:Function;
	
	private var _lastUpdated:Date;
	
	private var _receivedLV:LoadVars;
	//}
	
	public function InternodeNetUsageData(username:String, password:String, accountName:String) 
	{trace("constructing internode net usage data for " + username);
		//validate later so error can be propagated
		_username = username;
		_password = password;
		_accountName = accountName;
	}
	
	//{ interface methods
	public function init():Void
	{
		if (_username == undefined || _username == null || _username.length == 0) 
		{
			callOnError("Missing username - please check your widget configuration.");
			return;
		}
		
		if (_password == undefined || _password == null || _password.length == 0) 
		{
			callOnError("Missing password - please check your widget configuration.");
			return;
		}
		
		//use username as account name if none specified
		if (_accountName == undefined)
			_accountName = _username;
			
		_hasStarted = false;
	}
	
	public function start():Void
	{
		_hasStarted = true;
		
		//update every interval, and kick things off now
		setInterval(this, "startUpdate", UPDATE_INTERVAL);
		startUpdate();
	}

	public function hasStarted():Boolean
	{ 
		return _hasStarted;
	}
	
	public function loadLogo(target:MovieClip, instanceName:String, depth:Number):MovieClip
	{
		return target.attachMovie("ispLogo", instanceName, depth);
	}
	
	public function getLastUpdated():Date
	{
		return _lastUpdated;
	}
	
	public function setOnUpdated(f:Function):Void
	{
		_onUpdated = f;
	}
	
	public function setOnError(f:Function):Void
	{
		_onError = f;
	}
	
	public function getAccountName():String
	{
		return _accountName;
	}
	
	public function getRolloverDate():Date
	{
		return _rolloverDate;
	}
	
	public function hasOffPeak():Boolean
	{
		//no off-peak ever
		return false;
	}
	
	//returns true if currently in peak period. If no off-peak period, return true always.
	public function isPeak():Boolean
	{
		//no off-peak
		return true;
	}
	
	//in MB
	public function getPeakDataUsed():Number
	{
		return _peakDataUsed;
	}
	
	//in MB
	public function getPeakDataQuota():Number
	{
		return _peakDataQuota;
	}
	
	//in cents
	public function getPeakExcessCost():Number
	{
		return _peakExcessCost;
	}
	
	//in MB
	public function getOffPeakDataUsed():Number
	{
		//not used
		return 0;
	}
	
	//in MB
	public function getOffPeakDataQuota():Number
	{
		//not used
		return 0;
	}
	
	//in cents
	public function getOffPeakExcessCost():Number
	{
		//not used
		return 0;
	}
	//}
	
	private function callOnError(message:String):Void
	{
		if (_onError != null)
			_onError(message);
	}
	
	private function callOnUpdated():Void
	{
		if (_onUpdated != null)
			_onUpdated();
	}
	
	private function startUpdate():Void
	{
		var sendLV:LoadVars = new LoadVars();
		sendLV["username"] = _username;
		sendLV["password"] = _password;
		sendLV["iso"] = 1; //for ISO standard dates
		//sendLV.onLoad = Delegate.create(this, updateReceived);
		
		var url:String = "https://customer-webtools-api.internode.on.net/cgi-bin/padsl-usage";
		
		_receivedLV = new LoadVars();
		_receivedLV.onLoad = Delegate.create(this, updateReceived);
		
		sendLV.sendAndLoad(url, _receivedLV, "POST");
	}
	
	private function updateReceived(success:Boolean):Void
	{trace("update received");
		if (success == false)  
		{
			callOnError("Could not retrieve details from Internode servers.");
			return;
		}
		
		//find received data string
		var receivedData:String = null;
		for (var i in _receivedLV)
		{
			//only 2 set properties on received LV, one being onLoad and the other the data
			if (i != "onLoad")
			{
				receivedData = i;
				break;
			}
		}
		
		if (receivedData == null)
		{
			callOnError("No data received.");
			return;
		}
		
		//check if error message - if first char isn't numeric
		if (receivedData.charCodeAt(0) < 48 && receivedData.charCodeAt(0) > 57)
		{
			callOnError(receivedData);
			return;
		}
		
		var receivedDataBits:Array = receivedData.split(" ");

		if (receivedDataBits.length != 4)
		{
			callOnError("Unexpected amount of data received.");
			return;
		}
		
		//data used
		_peakDataUsed = parseFloat(receivedDataBits[0]);
		
		//data quota
		_peakDataQuota = parseFloat(receivedDataBits[1]);
		
		//rollover date
		//trace("rollover date str: " + receivedDataBits[2]);
		//trace("rollover year: " + parseInt(receivedDataBits[2].substr(0, 4)));
		//trace("rollover month: " + parseInt(receivedDataBits[2].substr(4, 2)));
		//trace("rollover day: " + parseInt(receivedDataBits[2].substr(6, 2)));
		_rolloverDate = new Date(parseInt(receivedDataBits[2].substr(0, 4)), 
								 parseInt(receivedDataBits[2].substr(4, 2)) - 1 /* zero-based months in AS */, 
								 parseInt(receivedDataBits[2].substr(6, 2)), 0, 0, 0, 0);
		
		//excess usage cost
		_peakExcessCost = parseFloat(receivedDataBits[3]);
		
		//changed to shaped (-1) if 0
		if (_peakExcessCost == 0)
			_peakExcessCost = -1;
			
		_lastUpdated = new Date();
		
		callOnUpdated();
	}
}