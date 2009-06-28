/* 
Copyright (c) 2008 Chumby Industries

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
import com.chumby.util.Delegate;
import com.chumby.util.MCUtil;
import com.chumby.util.xml.XmlUtil;
import mx.data.encoders.Num;

import netusage.INetUsageData;
import netusage.widgets.MessageOverlay;

class netusage.Main extends MovieClip
{	
	//{ constants
	private var ISP_LOGO_DEPTH:Number = 1;
	private var LASTUPDATEDTEXT_DEPTH:Number = 2;
	
	private var ACCOUNTNAMETEXT_DEPTH:Number = 10;
	
	private var DAYSLEFTVALUETEXT_DEPTH:Number = 20;
	private var DAYSLEFTTEXT_DEPTH:Number = 21;
	private var ROLLOVERTEXT_DEPTH:Number = 22;
	private var ROLLOVERDATETEXT_DEPTH:Number = 23;
	
	private var DATALEFTVALUETEXT_DEPTH:Number = 30;
	private var DATALEFTUNITSTEXT_DEPTH:Number = 31;
	private var DATALEFTTEXT_DEPTH:Number = 32;
	private var BUDGETTEXT_DEPTH:Number = 33;
	private var BUDGETVALUETEXT_DEPTH:Number = 34;
	
	private var MESSAGEOVERLAY_DEPTH:Number = 1000;
	
	//need to add up to 240
	private var HEADER_HEIGHT:Number = 30;
	private var ACCOUNTNAME_HEIGHT:Number = 24;
	private var MAININFO_HEIGHT:Number = 110;
	private var SUPPINFO_HEIGHT:Number = 60;
	private var USAGEBARS_HEIGHT:Number = 16;
	
	private var MC_WIDTH:Number = 320;
	private var MC_HEIGHT:Number = 240;
	
	private var MONTH_NAMES:Array = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
	//}
	
	//{ instance variables
	private var _netUsageData:INetUsageData = null;
	
	private var _lastUpdatedText:TextField;
	private var _accountNameText:TextField;
	private var _daysLeftValueText:TextField;
	private var _daysLeftText:TextField;
	private var _rolloverText:TextField;
	private var _rolloverDateText:TextField;
	
	private var _dataLeftValueText:TextField;
	private var _dataLeftUnitsText:TextField;
	private var _dataLeftText:TextField;
	private var _budgetText:TextField;
	private var _budgetValueText:TextField;
	
	private var _usagePercent:Number;
	private var _budgetPercent:Number;
	
	private var _messageOverlay:MessageOverlay = null;
	//}
	
	public function Main(netUsageData:INetUsageData)
	{	
		if (netUsageData == undefined || netUsageData == null)
			throw new Error("The netUsageData parameter cannot be null or undefined.");
		
		_netUsageData = netUsageData;
		
		//hook up callbacks
		_netUsageData.setOnError(Delegate.create(this, netUsageDataError));
		_netUsageData.setOnUpdated(Delegate.create(this, netUsageDataUpdated));
		
		//create UI
		generateUI();
		paintUIBG();
		
		//init net usage data
		_netUsageData.init();
		
		//needs to be after net usage data init for values to appear
		refreshUI();
		
		//stop here if errors during init so error message stays on screen
		if (isMessageOverlayShowing())
			return;

		//ask user to tap before downloading data to reduce strain on servers
		//many don't implement caching properly to prevent redundant calls when widget loads each time
		showStatus("Tap to get usage data", "Usage data is not real time. It is typically updated every half hour.\n\n" +
		           "This widget will update itself every 30 minutes while it is showing.");
	}
	
	private function generateUI():Void
	{
		var tf:TextFormat = null;
		var curY:Number = 0;
		
		//isp logo
		var ispLogo:MovieClip = _netUsageData.loadLogo(this, "ispLogo", ISP_LOGO_DEPTH);
		ispLogo._x = 10 /* gap */;
		ispLogo._y = 0;
		
		//work out scaling factor
		var ispLogoScalingFactor:Number = ispLogo._width / ispLogo._height;
		ispLogo._width = HEADER_HEIGHT * ispLogoScalingFactor;
		ispLogo._height = HEADER_HEIGHT;
		
		//last updated
		_lastUpdatedText = createTextField("lastUpdatedText", LASTUPDATEDTEXT_DEPTH, 0, curY + 5 /* gap */, MC_WIDTH - 10 /* gap */, HEADER_HEIGHT);
		tf = new TextFormat();
		with (tf)
		{
			align = "right";
			font = "Arial";
			size = 12;
			color = 0x999999;
		}
		_lastUpdatedText.setNewTextFormat(tf);
		
		//update every minute to reflect the relative last updated time
		setInterval(this, "updateLastUpdated", 60000);
		
		//account name
		curY += HEADER_HEIGHT;
		_accountNameText = createTextField("accountNameText", ACCOUNTNAMETEXT_DEPTH, 10 /* gap */, curY, MC_WIDTH, ACCOUNTNAME_HEIGHT);
		tf = new TextFormat();
		with (tf)
		{
			font = "Arial";
			size = 15;
			color = 0xFFFFFF;
			bold = true;
		}
		_accountNameText.setNewTextFormat(tf);
		
		//days left value
		curY += ACCOUNTNAME_HEIGHT + 10 /* gap */;
		_daysLeftValueText = createTextField("daysLeftValueText", DAYSLEFTVALUETEXT_DEPTH, 0, curY, MC_WIDTH / 2, 72);
		tf = new TextFormat();
		with (tf)
		{
			align = "center";
			font = "Arial";
			size = 63;
			color = 0xFFFFFF;
			bold = true;
		}
		_daysLeftValueText.setNewTextFormat(tf);
		
		//days left text
		_daysLeftText = createTextField("daysLeftText", DAYSLEFTTEXT_DEPTH, 0, curY + 72 + 10 /* for days left value and gap */, MC_WIDTH / 2, 24);
		tf = new TextFormat();
		with (tf)
		{
			align = "center";
			font = "Arial";
			size = 14;
			color = 0xFFFFFF;
		}
		_daysLeftText.setNewTextFormat(tf);
		
		//roll over text
		curY += MAININFO_HEIGHT;
		_rolloverText = createTextField("rolloverText", ROLLOVERTEXT_DEPTH, 0, curY, MC_WIDTH / 2, 20);
		tf = new TextFormat();
		with (tf)
		{
			align = "center";
			font = "Arial";
			size = 12;
			color = 0xFFFFFF;
		}
		_rolloverText.setNewTextFormat(tf);
		
		//roll over date text
		_rolloverDateText = createTextField("rolloverDateText", ROLLOVERDATETEXT_DEPTH, 0, curY + 20 /* height of roll over text */, MC_WIDTH / 2, 30);
		tf = new TextFormat();
		with (tf)
		{
			align = "center";
			font = "Arial";
			size = 16;
			color = 0xFFFFFF;
		}
		_rolloverDateText.setNewTextFormat(tf);
		
		//data left value text
		curY = HEADER_HEIGHT + ACCOUNTNAME_HEIGHT + 10 /* gap */; 
		_dataLeftValueText = createTextField("dataLeftValueText", DATALEFTVALUETEXT_DEPTH, MC_WIDTH / 2 + 4 /* gap */, curY, MC_WIDTH / 2, 72);
		tf = new TextFormat();
		with (tf)
		{
			align = "center";
			font = "Arial";
			size = 63;
			color = 0xFFFFFF;
			bold = true;
		}
		_dataLeftValueText.setNewTextFormat(tf);
		
		//data left units text
		_dataLeftUnitsText = createTextField("dataLeftUnitsText", DATALEFTUNITSTEXT_DEPTH, MC_WIDTH / 2, curY + (72 - 27) /* same baseline as data left value */, MC_WIDTH / 2, 30);
		tf = new TextFormat();
		with (tf)
		{
			font = "Arial";
			size = 16;
			color = 0xFFFFFF;
		}
		_dataLeftUnitsText.setNewTextFormat(tf);
		
		//data left text
		_dataLeftText = createTextField("dataLeftText", DATALEFTTEXT_DEPTH, MC_WIDTH / 2, curY + 72 + 10 /* for data left value and gap */, MC_WIDTH / 2, 24);
		tf = new TextFormat();
		with (tf)
		{
			align = "center";
			font = "Arial";
			size = 14;
			color = 0xFFFFFF;
		}
		_dataLeftText.setNewTextFormat(tf);
		
		//budget text
		curY += MAININFO_HEIGHT;
		_budgetText = createTextField("budgetText", BUDGETTEXT_DEPTH, MC_WIDTH / 2, curY, MC_WIDTH / 2, 20);
		tf = new TextFormat();
		with (tf)
		{
			align = "center";
			font = "Arial";
			size = 12;
			color = 0xFFFFFF;
		}
		_budgetText.setNewTextFormat(tf);
		
		//budget value text
		_budgetValueText = createTextField("budgetValueText", BUDGETVALUETEXT_DEPTH, MC_WIDTH / 2, curY + 20 /* for budget text */, MC_WIDTH / 2, 30);
		tf = new TextFormat();
		with (tf)
		{
			align = "center";
			font = "Arial";
			size = 16;
			color = 0xFFFFFF;
		}
		_budgetValueText.setNewTextFormat(tf);
	}
	
	private function updateLastUpdated():Void
	{trace("updateLastUpdated");
		if (_netUsageData == undefined || _netUsageData == null || !_netUsageData.hasStarted())
			//do nothing - user needs to tap screen
			break;
		else if (_netUsageData.hasStarted() && (_netUsageData.getLastUpdated() == undefined || _netUsageData.getLastUpdated() == null))
			_lastUpdatedText.text = "loading...";
		else
			_lastUpdatedText.text = "last updated: " + formatDateAsHumanDateWithTime(_netUsageData.getLastUpdated());
	}
	
	private function paintUIBG():Void
	{
		var curY:Number = 0;
		
		//white header
		moveTo(0, curY);
		beginFill(0xFFFFFF, 100);
		lineTo(MC_WIDTH, 0);
		curY += HEADER_HEIGHT;
		lineTo(MC_WIDTH, curY);
		lineTo(0, curY);
		endFill();
		
		//grey account name
		moveTo(0, curY);
		beginFill(0x333333, 100);
		lineTo(MC_WIDTH, curY);
		curY += ACCOUNTNAME_HEIGHT;
		lineTo(MC_WIDTH, curY);
		lineTo(0, curY);
		
		//draw dividing line
		moveTo(MC_WIDTH / 2 - 1, curY);
		beginFill(0x333333, 100);
		lineTo(MC_WIDTH / 2, curY);
		curY += MAININFO_HEIGHT + SUPPINFO_HEIGHT;
		lineTo(MC_WIDTH / 2, curY);
		lineTo(MC_WIDTH / 2 - 1, curY);
		endFill();
		
		//draw separator line
		moveTo(0, curY - 1);
		beginFill(0x333333, 100);
		lineTo(MC_WIDTH, curY - 1);
		lineTo(MC_WIDTH, curY);
		lineTo(0, curY);
		endFill();
		
		//paint usage bars
		var usageBarHeight:Number = USAGEBARS_HEIGHT / 2;
		
		//actual
		moveTo(0, curY);
		beginFill(0xFFFF00, 100);
		lineTo(MC_WIDTH * _usagePercent, curY);
		curY += usageBarHeight;
		lineTo(MC_WIDTH * _usagePercent, curY);
		lineTo(0, curY);
		endFill();
		
		//budgeted
		moveTo(0, curY);
		//green for under budget, red for over
		beginFill((_usagePercent > _budgetPercent ? 0xFF0000 : 0x80FF00), 100);
		lineTo(MC_WIDTH * _budgetPercent, curY);
		curY += usageBarHeight;
		lineTo(MC_WIDTH * _budgetPercent, curY);
		lineTo(0, curY);
		endFill();
	}
	
	private function refreshUI():Void
	{trace("refresh UI");
		updateLastUpdated();
		_accountNameText.text = _netUsageData.getAccountName();

		//stop here if there is no data available
		if (_netUsageData == undefined || _netUsageData == null || !_netUsageData.hasStarted() || 
			_netUsageData.getLastUpdated() == undefined || _netUsageData.getLastUpdated() == null)
			return;
		
		//calculate days left
		var daysLeft:Number = _netUsageData.getRolloverDate().getTime() - (new Date()).getTime();
		daysLeft = Math.floor(daysLeft / (1000 * 60 * 60 * 24)) + 1; //iiNet says to include today in this count
		
		_daysLeftValueText.text = String(daysLeft);
		
		if (daysLeft == 1)
			_daysLeftText.text = "day left";
		else
			_daysLeftText.text = "days left";
		
		_rolloverText.text = "rolls over on";
		_rolloverDateText.text = addOrdinalPrefixToNumber(_netUsageData.getRolloverDate().getDate()) + " " + MONTH_NAMES[_netUsageData.getRolloverDate().getMonth()];
		
		//calculate data left
		var dataLeft:Number;
		var dataUnits:String;
		
		if (_netUsageData.isPeak())
			dataLeft = _netUsageData.getPeakDataQuota() - _netUsageData.getPeakDataUsed();
		else
			dataLeft = _netUsageData.getOffPeakDataQuota() - _netUsageData.getOffPeakDataUsed();
		
		if (Math.abs(dataLeft) >= 1000)
		{
			dataLeft /= 1000;
			dataUnits = "gb";
		}
		else
		{
			dataUnits = "mb";
		}
		
		//round to necessary precision
		if (Math.abs(dataLeft) >= 10)
		{
			dataLeft = Math.round(dataLeft); //zero-dp precision
		}
		else
		{
			dataLeft = dataLeft * 10; //1-dp precision
			dataLeft = Math.round(dataLeft);
			dataLeft = dataLeft / 10;
		}
		
		_dataLeftValueText.text = String(Math.abs(dataLeft));
		_dataLeftUnitsText.text = dataUnits;
		
		//shrink data left value so units fit in and stay center
		_dataLeftValueText._width = MC_WIDTH / 2 - _dataLeftUnitsText.textWidth - 6 /* account for other layout diffs */;
		
		//place units right after data left value
		_dataLeftUnitsText._x = _dataLeftValueText._x + (_dataLeftValueText._width / 2 + _dataLeftValueText.textWidth / 2) - 5 /* gap is too big anyway */;
		
		if (dataLeft >= 0)
		{
			if (_netUsageData.hasOffPeak())
				_dataLeftText.text = _netUsageData.isPeak() ? "peak data left" : "offpeak data left";
			else
				_dataLeftText.text = "data left";
			
			//calculate budgeted data
			var lastRolloverDate:Date = new Date(_netUsageData.getRolloverDate().getTime());
			lastRolloverDate.setMonth(lastRolloverDate.getMonth() - 1);
			
			var hoursInBudget:Number = _netUsageData.getRolloverDate().getTime() - lastRolloverDate.getTime();
			hoursInBudget = Math.floor(hoursInBudget / (1000 * 60 * 60));
			
			var curHourInBudget:Number = (new Date()).getTime() - lastRolloverDate.getTime();
			curHourInBudget = Math.floor(curHourInBudget / (1000 * 60 * 60));
			
			var budgetNow:Number = 0;
			var budgetDiff:Number = 0;
			if (_netUsageData.isPeak())
			{
				budgetNow = (curHourInBudget / hoursInBudget) * _netUsageData.getPeakDataQuota();
				budgetDiff = budgetNow - _netUsageData.getPeakDataUsed();
				
				//for painting usage bars
				_usagePercent = _netUsageData.getPeakDataUsed() / _netUsageData.getPeakDataQuota();
				_budgetPercent = curHourInBudget / hoursInBudget;
			}
			else
			{
				budgetNow = (curHourInBudget / hoursInBudget) * _netUsageData.getOffPeakDataQuota();
				budgetDiff = budgetNow - _netUsageData.getOffPeakDataUsed();
				
				//for painting usage bars
				_usagePercent = _netUsageData.getOffPeakDataUsed() / _netUsageData.getOffPeakDataQuota();
				_budgetPercent = curHourInBudget / hoursInBudget;
			}
			
			budgetDiff = Math.floor(budgetDiff);
				
			if (budgetDiff > 0)
			{
				_budgetText.text = "under budget by";
				_budgetValueText.text = budgetDiff >= 1000 ? (budgetDiff / 1000) + " gb" : budgetDiff + " mb";
			}
			else
			{
				budgetDiff = Math.abs(budgetDiff);
				_budgetText.text = "over budget by";
				_budgetValueText.text = budgetDiff >= 1000 ? (budgetDiff / 1000) + " gb" : budgetDiff + " mb";
				
				var tf:TextFormat = new TextFormat();
				with (tf)
				{
					color = 0xFFFF00;
				}
				_budgetText.setTextFormat(tf);
				_budgetValueText.setTextFormat(tf);
			}
		}
		else
		{
			//over quota
			if (_netUsageData.hasOffPeak())
				_dataLeftText.text = _netUsageData.isPeak() ? "over peak quota" : "over offpeak quota";
			else
				_dataLeftText.text = "over quota";
			
			var tf:TextFormat = new TextFormat();
			with (tf)
			{
				color = 0xFFFF00;
			}
			_dataLeftValueText.setTextFormat(tf);
			_dataLeftUnitsText.setTextFormat(tf);
			_dataLeftText.setTextFormat(tf);
			
			//for painting usage bars - make them paint full bars
			_usagePercent = 1.1; //slightly more so red over-budget bars are painted
			_budgetPercent = 1; 
			
			if (_netUsageData.isPeak())
			{
				if (_netUsageData.getPeakExcessCost() >= 0)
				{
					_budgetText.text = "excess charged at";
					_budgetValueText.text = "$" + _netUsageData.getPeakExcessCost() + " / mb";
				}
				else
				{
					_budgetText.text = "";
					_budgetValueText.text = "shaped";
				}
			}
			else
			{
				if (_netUsageData.getOffPeakExcessCost() >= 0)
				{
					_budgetText.text = "excess charged at";
					_budgetValueText.text = "$" + _netUsageData.getOffPeakExcessCost() + " / mb";
				}
				else
				{
					_budgetText.text = "";
					_budgetValueText.text = "shaped";
				}
			}
		}
		
		//refresh usage bars
		paintUIBG();
	}
	
	private function netUsageDataError(message:String):Void
	{trace("show error");
		showError(message);
	}
	
	private function netUsageDataUpdated():Void
	{trace("net usage data updated");
		refreshUI();
		
		removeMessageOverlay();
	}
	
	//{ date formatting functions
	private function addOrdinalPrefixToNumber(n:Number):String
	{
		//ignore negative numbers
		if (n < 0)
			return String(n);
		
		var temp:Number;
		
		temp = n;
		while (temp >= 10)
			temp -= 10;
		
		// st
		if (temp == 1 && n != 11)
			return n + "st";
		
		//nd
		if (temp == 2 && n != 12)
			return n + "nd";
		
		//rd
		if (temp == 3 && n != 13)
			return n + "rd";
		
		return n + "th";
	}
	private function formatDateAsHumanDateWithTime(date:Date):String
	{
		var diffMS:Number = (new Date()).getTime() - date.getTime();
		var diff:Number;
		var absDiff:Number = Math.abs(diffMS);

		if (absDiff < 1000 /* 1 second */)
		{
			return "just now";
		}
		if (absDiff < 60000 /* 1 minute */)
		{
			diff = Math.round(absDiff / 1000);
			if (diffMS < 0)
				return diff == 1 ? "in " + diff + " second" : "in " + diff + " seconds";
			else
				return diff == 1 ? diff + " second ago" : diff + " seconds ago";
		}
		else if (absDiff < 60000 * 60 /* 1 hour */)
		{
			diff = Math.round(absDiff / 60000);
			if (diffMS < 0)
				return diff == 1 ? "in " + diff + " minute" : "in " + diff + " minutes";
			else
				return diff == 1 ? diff + " minute ago" : diff + " minutes ago";
		}
		else
		{
			var dateStr:String = "";
			
			//if today
			var today:Date = new Date();
			if (today.getDate() == date.getDate() && today.getMonth() == date.getMonth() && today.getYear() == date.getYear())
				dateStr += "today ";
			//tomorrow
			else if (date.getTime() - today.getTime() < (1000 * 60 * 60 * 24))
				dateStr += "tomorrow ";
			else
				dateStr += addOrdinalPrefixToNumber(date.getDate()) + " " + MONTH_NAMES[date.getMonth()] + " ";
			
			//calculate 12-hour time
			var hour:Number = date.getHours();
			if (hour > 12)
				dateStr += (hour - 12) + ":" + date.getMinutes() + " pm";
			else
				dateStr += hour + ":" + date.getMinutes() + " am";
			
			return dateStr;
		}
	}
	//}
	
	//{ message overlay functions
	private function isMessageOverlayShowing():Boolean
	{
		return _messageOverlay != null;
	}
	
	private function showMessageOverlay(messageTitle:String, message:String):Void
	{
		if (!isMessageOverlayShowing())
		{
			//does not exist, create it
			//keep header and account name showing
			_messageOverlay = 
					MCUtil.CreateWithClass(
							MessageOverlay, this, "messageOverlay", MESSAGEOVERLAY_DEPTH, {_y:HEADER_HEIGHT + ACCOUNTNAME_HEIGHT} );
							
			//attach handlers
			_messageOverlay.onClicked = Delegate.create(this, messageOverlayClicked);
		}
		
		//set messages
		_messageOverlay.messageTitle = messageTitle;
		_messageOverlay.message = message;
	}
	
	private function removeMessageOverlay():Void
	{
		if (_messageOverlay != null)
		{
			_messageOverlay.removeOverlay();
			_messageOverlay.removeMovieClip();
			_messageOverlay = null;
		}
	}
	
	private function messageOverlayClicked():Void
	{
		//start updating if has not been started
		if (!_netUsageData.hasStarted())
		{
			showStatus("loading", "contacting your ISP...");
			_netUsageData.start();
		}
	}
	//}
	
	//{ status methods
	private function showStatus(title:String, message:String):Void
	{
		showMessageOverlay(title, message);
	}
	
	private function showError(str:String):Void
	{
		showMessageOverlay("an error occurred.", str);
	}
	//}
}
