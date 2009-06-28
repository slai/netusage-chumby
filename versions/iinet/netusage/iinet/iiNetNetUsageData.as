/**
 * ...
 * @author Samuel Lai
 */
import netusage.INetUsageData;
import netusage.util.StringUtil;

import com.chumby.util.xml.XmlUtil;
import com.chumby.util.Delegate;
 
class netusage.iinet.iiNetNetUsageData implements INetUsageData
{
	//{ constants
	private var UPDATE_INTERVAL:Number = 60000 * 30; //30 minutes
	//}
	
	//{ instance variables
	private var _hasStarted:Boolean;
	
	private var _username:String;
	private var _password:String;
	private var _accountName:String;
	private var _planName:String;
	
	private var _rolloverDate:Date;
	
	private var _hasOffPeak:Boolean;
	private var _isPeak:Boolean;
	private var _peakDataUsed:Number;
	private var _peakDataQuota:Number;
	private var _peakExcessCost:Number;
	
	private var _offPeakDataUsed:Number;
	private var _offPeakDataQuota:Number;
	private var _offPeakExcessCost:Number;
	
	private var _onError:Function;
	private var _onUpdated:Function;
	
	private var _lastUpdated:Date;
	
	private var _xml:XML;
	//}
	
	public function iiNetNetUsageData(username:String, password:String, accountName:String) 
	{trace("constructing iinet net usage data for " + username);
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
	
		//TEST VALUES
		/*_rolloverDate = new Date(2009, 11, 28, 0, 0, 0, 0); //zero-based months, grrr
		_isPeak = false;
		_peakDataQuota = 25000;
		_peakDataUsed = 24404;
		_peakExcessCost = 0.02; //-1 == shaped
		_offPeakDataQuota = 45000;
		_offPeakDataUsed = 45203;
		_offPeakExcessCost = 0.02; //-1 == shaped
		
		_lastUpdated = new Date();
		
		callOnUpdated();*/
		
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
		if (StringUtil.isNullOrEmpty(_planName))
			return _accountName;
		else
			return _accountName + " (" + _planName + ")";
	}
	
	public function getRolloverDate():Date
	{
		return _rolloverDate;
	}
	
	public function hasOffPeak():Boolean
	{
		return _hasOffPeak;
	}
	
	//returns true if currently in peak period. If no off-peak period, return true always.
	public function isPeak():Boolean
	{
		return _isPeak;
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
		return _offPeakDataUsed;
	}
	
	//in MB
	public function getOffPeakDataQuota():Number
	{
		return _offPeakDataQuota;
	}
	
	//in cents
	public function getOffPeakExcessCost():Number
	{
		return _offPeakExcessCost;
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
		_xml = new XML();
		_xml.ignoreWhite = true;
		_xml.onLoad = Delegate.create(this, updateReceived);
		
		var url:String = "https://toolbox.iinet.net.au/cgi-bin/new/volume_usage_xml.cgi?action=login&username=" + escape(_username) + "&password=" + escape(_password);

		_xml.load(url);
	}
	
	private function updateReceived(success:Boolean):Void
	{
		if (success == false)  
		{
			callOnError("Could not retrieve details from iiNet servers.");
			return;
		}
		
		var curNode:XMLNode;
		var volumeUsageNode:XMLNode;
		
		//check if error
		curNode = XmlUtil.firstChildOfType(_xml.firstChild, "error");
		if (curNode != null)
		{
			callOnError(curNode.firstChild.nodeValue + " - please check your profile configuration");
			return;
		}
		
		//get plan name if it doesn't exist
		curNode = XmlUtil.firstChildOfType(_xml.firstChild, "account_info");
		if (curNode != null)
		{
			curNode = XmlUtil.firstChildOfType(curNode, "plan");
			if (curNode != null)
				_planName = curNode.firstChild.nodeValue;
		}

		//get rollover date details
		volumeUsageNode = XmlUtil.firstChildOfType(_xml.firstChild, "volume_usage");
		if (volumeUsageNode == null)
		{
			//the volume_usage node contains everything else, so fail if not found
			callOnError("Invalid XML - volume_usage.");
			return;
		}
		
		curNode = XmlUtil.firstChildOfType(volumeUsageNode, "quota_reset");
		if (curNode != null)
		{
			curNode = XmlUtil.firstChildOfType(curNode, "anniversary");
			if (curNode != null)
			{
				var anniversaryDate:Number = parseInt(curNode.firstChild.nodeValue);
				_rolloverDate = new Date();
				
				//if the anniversary date has passed, the next anniversary date must be next month
				if (_rolloverDate.getDate() >= anniversaryDate)
					_rolloverDate.setMonth(_rolloverDate.getMonth() + 1);
					
				_rolloverDate.setDate(anniversaryDate);
				
				//clear out time values
				_rolloverDate.setHours(0);
				_rolloverDate.setMinutes(0);
				_rolloverDate.setSeconds(0);
				_rolloverDate.setMilliseconds(0);
			}
		}
		
		//determine if in peak period
		var offpeakStart:Number = -1;
		var offpeakEnd:Number = -1;
		
		curNode = XmlUtil.firstChildOfType(volumeUsageNode, "offpeak_start");
		if (curNode != null)
		{
			//no replace function, so split then join to eliminate the colon separator
			offpeakStart = parseInt(curNode.firstChild.nodeValue.split(":").join(""));
		}
		
		curNode = XmlUtil.firstChildOfType(volumeUsageNode, "offpeak_end");
		if (curNode != null)
		{
			offpeakEnd = parseInt(curNode.firstChild.nodeValue.split(":").join(""));
		}
		
		//trace("offpeak start: " + offpeakStart);
		//trace("offpeak end: " + offpeakEnd);
		
		//check if there is a peak/offpeak
		if (offpeakStart == -1 && offpeakEnd == -1)
		{
			//no offpeak
			_hasOffPeak = false;
			_isPeak = true;
		}
		else
		{
			//offpeak exists
			_hasOffPeak = true;
			
			var today:Date = new Date();
			//get current time in hhmm format
			var curTimeDigits:Number = today.getHours() * 100 + today.getMinutes();
			if (curTimeDigits >= offpeakStart && curTimeDigits <= offpeakEnd)
				_isPeak = false;
			else
				_isPeak = true;
		}
		
		//get data info
		curNode = XmlUtil.firstChildOfType(volumeUsageNode, "expected_traffic_types");
		if (curNode != null)
		{
			var dataNodes:Array = XmlUtil.childrenOfType(curNode, "type");
			
			
			for (var i:Number = 0; i < dataNodes.length; i++)
			{
				var x:XMLNode = dataNodes[i];
				
				//check if peak
				if (x.attributes["classification"] == "peak")
				{
					_peakDataUsed = x.attributes["used"] / 1000000; //bytes to mb
					
					curNode = XmlUtil.firstChildOfType(x, "quota_allocation");
					if (curNode != null)
						_peakDataQuota = parseInt(curNode.firstChild.nodeValue); //this is in mb already
					
					_peakExcessCost = -1; //always shaped AFAIK
				}
				//check if offpeak
				else if (x.attributes["classification"] == "offpeak")
				{
					_offPeakDataUsed = x.attributes["used"] / 1000000; //bytes to mb
					
					curNode = XmlUtil.firstChildOfType(x, "quota_allocation");
					if (curNode != null)
						_offPeakDataQuota = parseInt(curNode.firstChild.nodeValue); //this is in mb already
					
					_offPeakExcessCost = -1; //always shaped AFAIK
				}
			}
		}
		
		_lastUpdated = new Date();
		
		callOnUpdated();
	}
}