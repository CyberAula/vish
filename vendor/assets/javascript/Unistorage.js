/**
 * Provides Cross-browser key-value storage
 * Use the best Web Storage technology available for a particular browser
 */

Unistorage = (function(undefined){
	
	var _Unistorage;

	var init = function(callback){
		//Decide the better web techonology to use
		if(Unistorage.WebSQLDatabase.isSupported()){
			_Unistorage = Unistorage.WebSQLDatabase;
		} else if(Unistorage.LocalStorage.isSupported()){
			_Unistorage = Unistorage.LocalStorage;
		} else {
			//TODO: IndexedDB
		}
		_Unistorage.init(callback);
	}

	var store = function(key,value,callback){
		_Unistorage.store(key,value,callback);
	}

	var get = function(key,callback){
		_Unistorage.get(key,callback);
	}

	var storeJSON = function(key,value,callback){
		store(key,JSON.stringify(value),function(res){
			Unistorage.Utils.secureCallback(callback,res);
		});
	}

	var getJSON = function(key,callback){
		get(key,function(value){
			Unistorage.Utils.secureCallback(callback,JSON.parse(value));
		});
	}

	var remove = function(key,callback){
		_Unistorage.remove(key,callback);
	}

	var reset = function(callback){
		_Unistorage.reset(callback);
	}

    return {
    	init			: init,
		store 			: store,
		get   			: get,
		remove 			: remove,
		reset			: reset,
		storeJSON 		: storeJSON,
		getJSON 		: getJSON
    };

}) ();


Unistorage.LocalStorage  = (function(undefined){

	var isSupported = function(){
		return 'localStorage' in window && window['localStorage'] !== null;
	}

	var init = function(callback){ 
		Unistorage.Utils.secureCallback(callback,true);
	}

	var store = function(key,value,callback){
		Unistorage.Utils.secureCallback(callback,localStorage.setItem(key, value));
	}

	var get = function(key,callback){
		Unistorage.Utils.secureCallback(callback,localStorage.getItem(key));
	}

	var remove = function(key,callback){
		Unistorage.Utils.secureCallback(callback,localStorage.removeItem(key));
	}

	var reset = function(callback){
		Unistorage.Utils.secureCallback(callback,localStorage.clear());
	}

	var _getStimatedQuota = function(callback){
		var estimation = encodeURIComponent(JSON.stringify(localStorage)).length;
		Unistorage.Utils.secureCallback(callback,estimation);
	}

    return {
    	init			: init,
		isSupported 	: isSupported,
		store 			: store,
		get   			: get,
		remove 			: remove,
		reset			: reset
    };

}) ();


Unistorage.WebSQLDatabase  = (function(undefined){

	var db;
	var tableName = "pairs";

	var init = function(callback){
		//Reserv 10 Mb initially
		db = openDatabase('UnistorageSQLDatabase','1.0','Unistorage SQL Database', 10 * 1024 * 1024);

		//Create table "values" to store key-value pairs
		db.transaction(function(tx) {
		  tx.executeSql('CREATE TABLE IF NOT EXISTS '+tableName+'(key primary key, value)',
		  	null,function(tx){
		  		//Success callback
		  		Unistorage.Utils.secureCallback(callback,true);
		  	},function(tx,error){
		  		Unistorage.Utils.secureCallback(callback,error);
		  	});
		});
	}

	var isSupported = function(){
		return window.openDatabase;
	}

	var store = function(key,value,callback){
		if(get(key,function(existingValue){
			if(existingValue===null){
				_save(key,value,callback);
			} else {
				_update(key,value,callback);
			}
		}));
	}

	var _save = function(key,value,callback){
		db.transaction(function(tx) {
		  tx.executeSql('INSERT INTO '+tableName+'(key,value) VALUES (?,?)',[key,value], 
		  	function(tx) {
		    	//Success
		    	Unistorage.Utils.secureCallback(callback,true);
		  },function(tx,error){
		  		Unistorage.Utils.secureCallback(callback,error);
		  });
		});
	}

	var _update = function(key,newValue,callback){
		db.transaction(function(tx) {
			tx.executeSql('UPDATE '+tableName+' SET value = ? where key = ?',[newValue,key], 
				function(tx) {
					//Success
					Unistorage.Utils.secureCallback(callback,true);
				},function(tx,error){
					Unistorage.Utils.secureCallback(callback,error);
			});
		});
	}

	var get = function(key,callback){
		db.transaction(function(tx) {
		    tx.executeSql('SELECT * FROM '+tableName+' where key="' + key + '"', [], function(tx, results) {
		      if(results.rows.length>0){
		      	Unistorage.Utils.secureCallback(callback,results.rows.item(0).value);
		      } else {
		      	Unistorage.Utils.secureCallback(callback,null);
		      }
		    });
	  	});
	}

	var remove = function(key,callback){
		db.transaction(function(tx) {
		  tx.executeSql('DELETE FROM '+tableName+' WHERE KEY=?',[key], 
		  	function(tx) {
		    	//Success
		    	Unistorage.Utils.secureCallback(callback,true);
		  },function(tx,error){
		  		Unistorage.Utils.secureCallback(callback,error);
		  });
		});
	}

	var reset = function(callback){
		db.transaction(function(tx) {
		  tx.executeSql('DROP TABLE IF EXISTS ' + tableName,
		  	null,function(tx){
		  		//Success callback
		  		Unistorage.Utils.secureCallback(callback,true);
		  	},function(tx,error){
		  		Unistorage.Utils.secureCallback(callback,error);
		  	});
		});
	}

    return {
    	init			: init,
		isSupported 	: isSupported,
		store 			: store,
		get   			: get,
		remove 			: remove,
		reset			: reset
    };
}) ();


Unistorage.Utils  = (function(undefined){

	var secureCallback = function(callback,param){
		if(typeof callback==="function"){
			callback(param);
		}
	}

    return {
    	secureCallback	: secureCallback
    };

}) ();







