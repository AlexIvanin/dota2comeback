SteamID = function(input) {
	if (typeof input !== 'undefined') {
		if (this.IsCommunityID(input) !== null) {
			return this.SetCommunityID(input);
		} else if ( this.IsSteam2(input) !== null) {
			return this.SetSteam2(input);
		} else {
			return this.SetAccountID(input);
		}
	}
	return this;
};

SteamID.prototype = {
	AccountID: 0,
	IsCommunityID: function(CommunityID) {
		if (typeof CommunityID !== 'string') {
			return null;
		}
		return CommunityID.match(/^7656119([0-9]{10})$/);
	},
	IsSteam2: function(SteamID) {
		if (typeof SteamID !== 'string') {
			return null;
		}
		return SteamID.match(/^STEAM_[0-5]:([0-1]):([0-9]+)$/);
	},
	SetAccountID: function(AccountID) {
		if (typeof AccountID === 'number') {
			this.AccountID = AccountID;
		} else if (typeof AccountID === 'string' && !isNaN(AccountID)) {
			this.AccountID = parseInt( AccountID, 10 );
		} else {
			return false;
		}
		return this;
	},
	SetCommunityID: function(CommunityID) {
		CommunityID = this.IsCommunityID(CommunityID);
		if (CommunityID === null) {
			return false;
		}
		CommunityID = CommunityID[0].substring(7);
		var ID = CommunityID % 2;
		CommunityID = (CommunityID - ID - 7960265728) / 2;
		this.AccountID = (CommunityID << 1) | ID;
		return this;
	},
	SetSteam2: function(SteamID) {
		SteamID = this.IsSteam2(SteamID);
		if (SteamID === null) {
			return false;
		}
		this.AccountID = (SteamID[2] << 1) | SteamID[1];
		return this;
	},
	GetCommunityID: function() {
		return '7656119' + (7960265728 + this.AccountID);
	},
	GetSteam2: function() {
		return 'STEAM_0:' + (this.AccountID & 1) + ':' + (this.AccountID >> 1);
	},
	GetSteam3: function() {
		return '[U:1:' + this.AccountID + ']';
	},

	GetAccountID: function() {
		return this.AccountID;
	}
};