/**
 * ...
 * @author Samuel Lai
 */
import netusage.INetUsageData;
import netusage.util.StringUtil;

import com.chumby.util.xml.XmlUtil;
import com.chumby.util.Delegate;
 
class netusage.amnet.AmnetNetUsageData implements INetUsageData
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
	
	public function AmnetNetUsageData(username:String, password:String, accountName:String) 
	{trace("constructing amnet net usage data for " + username);
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
		//request xml
		var reqXml:XML = new XML(
			'<?xml version="1.0" encoding="utf-8"?>' +
			'<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
				'<soap:Body>' +
					'<GetCurrentPeakUsage xmlns="http://au.com.amnet.memberutils/">' +
						'<username>' + escape(_username) + '</username>' +
						'<password>' + escape(_password) + '</password>' +
					'</GetCurrentPeakUsage>' +
				'</soap:Body>' +
			'</soap:Envelope>'
		);
		
		reqXml.ignoreWhite = true;
		reqXml.contentType = "text/xml";
		
		var reqUrl:String = "https://memberutils.amnet.com.au/usage.asmx?op=GetCurrentPeakUsage";

		//response xml
		_xml = new XML();
		_xml.ignoreWhite = true;
		_xml.onLoad = Delegate.create(this, updateReceived);
		
		//send request
		reqXml.sendAndLoad(reqUrl, _xml);
	}
	
	private function updateReceived(success:Boolean):Void
	{
		if (success == false)  
		{
			callOnError("Could not retrieve details from Amnet servers.");
			return;
		}
		
		var curNode:XMLNode;
		var resultNode:XMLNode;
		
		//navigate to the result node
		curNode = XmlUtil.firstChildOfType(_xml.firstChild, "soap:Body");
		if (curNode == null)
		{
			callOnError("soap:Body not found in response from ISP.");
			return;
		}
		
		curNode = XmlUtil.firstChildOfType(curNode, "GetCurrentPeakUsageResponse");
		if (curNode == null)
		{
			callOnError("GetCurrentPeakUsageResponse not found in response from ISP.");
			return;
		}
		
		curNode = XmlUtil.firstChildOfType(curNode, "GetCurrentPeakUsageResult");
		if (curNode == null)
		{
			callOnError("GetCurrentPeakUsageResult not found in response from ISP.");
			return;
		}
		
		//if no children, means there's no data, probably due to authentication error
		if (curNode.childNodes.length == 0)
		{
			callOnError("Authentication failed - please check your username and password.");
			return;
		}
		
		//found result node!
		resultNode = curNode;
		
		//all plans have off peak quotas
		_hasOffPeak = true;
		
		//determine if in peak period
		var offpeakStart:Number = -1;
		var offpeakEnd:Number = -1;
		
		//PEAK is from 7am to 12am (therefore offpeak is 12am to 7am).
		//Exception is Saturday - all day off peak.
		var today:Date = new Date();
		if (today.getDay() == 6 /* Saturday */)
			_isPeak = false;
		
		//check if before 7am (as offpeak is 12am to 7am, or 0 to 7)
		else if (today.getHours() < 7)
			_isPeak = false;
		
		//we're in peak period!
		else
			_isPeak = true;
		
		curNode = XmlUtil.firstChildOfType(resultNode, "AllowanceList");
		if (curNode != null)
		{
			//get plan name
			curNode = XmlUtil.firstChildOfType(curNode, "RateGroupName");
			if (curNode != null)
				_planName = curNode.firstChild.nodeValue;
			
			//get data quotas
			curNode = curNode.parentNode;
			curNode = XmlUtil.firstChildOfType(curNode, "Allowances");
			if (curNode != null)
			{
				var allowanceNodes:Array = XmlUtil.childrenOfType(curNode, "Allowance");
				
				for (var i:String in allowanceNodes)
				{
					curNode = allowanceNodes[i];
					var allowancePeriod:String = null;
					var allowanceDirection:String = null;
					var allowanceClass:String = null;
					var allowanceData:Number = 0;
					
					//get class value
					curNode = XmlUtil.firstChildOfType(curNode, "Class");
					if (curNode != null)
						allowanceClass = curNode.firstChild.nodeValue;
					
					//only want 'other' class allowances (not showing peering)
					if (allowanceClass != "Other")
						continue;
						
					//get direction value
					curNode = curNode.parentNode;
					curNode = XmlUtil.firstChildOfType(curNode, "Direction");
					if (curNode != null)
						allowanceDirection = curNode.firstChild.nodeValue;
						
					//only want 'download' allowances (not showing upload)
					//currently only download is counted, so this is for defensive purposes
					if (allowanceDirection != "Download")
						continue;
						
					//get period value
					curNode = curNode.parentNode;
					curNode = XmlUtil.firstChildOfType(curNode, "Period");
					if (curNode != null)
						allowancePeriod = curNode.firstChild.nodeValue;
						
					//get data value
					curNode = curNode.parentNode;
					curNode = XmlUtil.firstChildOfType(curNode, "Octets");
					if (curNode != null)
						allowanceData = parseInt(curNode.firstChild.nodeValue) / 1000 / 1000; //in bytes initially
					
					//store accordingly
					if (allowancePeriod == "Peak")
						_peakDataQuota = allowanceData;
					else if (allowancePeriod == "Offpeak")
						_offPeakDataQuota = allowanceData;
				}
			}
		}

		//get data used
		curNode = XmlUtil.firstChildOfType(resultNode, "Period");
		if (curNode != null)
		{
			curNode = XmlUtil.firstChildOfType(curNode, "Summary");
			if (curNode != null)
			{
				curNode = XmlUtil.firstChildOfType(curNode, "PeakOtherOctetsIn");
				if (curNode != null)
					_peakDataUsed = parseInt(curNode.firstChild.nodeValue) / 1000 / 1000; //this is in bytes initially
				
				curNode = curNode.parentNode;
				curNode = XmlUtil.firstChildOfType(curNode, "OffpeakOtherOctetsIn");
				if (curNode != null)
					_offPeakDataUsed = parseInt(curNode.firstChild.nodeValue) / 1000 / 1000; //this is in bytes initially
			}
		}
		
		//all plans are shaped
		//-1 == shaped
		_offPeakExcessCost = -1;
		_peakExcessCost = -1;
		
		//get rollover date
		curNode = XmlUtil.firstChildOfType(resultNode, "Period");
		if (curNode != null)
		{
			curNode = XmlUtil.firstChildOfType(curNode, "NextPeriodStart");
			if (curNode != null)
				_rolloverDate = xmlDateStringToDate(curNode.firstChild.nodeValue);
		}
		
		_lastUpdated = new Date();
		
		callOnUpdated();
	}
	
	private function xmlDateStringToDate(dateString:String):Date
	{
		//validate
		if (dateString == null || dateString.length != 19 || dateString.indexOf("T") < 0)
			return null;
		
		var date:Date = new Date();
		date.setFullYear(parseInt(dateString.substr(0, 4)));
		date.setMonth(parseInt(dateString.substr(5, 2)) - 1); //month is zero-based, grrr
		date.setDate(parseInt(dateString.substr(8, 2)));
		date.setHours(parseInt(dateString.substr(11, 2)));
		date.setMinutes(parseInt(dateString.substr(14, 2)));
		date.setSeconds(0);
		date.setMilliseconds(0);
		
		return date;
	}
}