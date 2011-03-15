<?php

/***********************************************
* File      :   utils.php
* Project   :   Z-Push
* Descr     :   
*
* Created   :   03.04.2008
*
*  Zarafa Deutschland GmbH, www.zarafaserver.de
* This file is distributed under GPL v2.
* Consult LICENSE file for details
************************************************/

// saves information about folder data for a specific device    
function _saveFolderData($devid, $folders) {
    if (!is_array($folders) || empty ($folders))
        return false;

    $unique_folders = array ();

    foreach ($folders as $folder) {    
        if (!isset($folder->type))
            continue;
    	
        // don't save folder-ids for emails
        if ($folder->type == SYNC_FOLDER_TYPE_INBOX)
            continue;

        // no folder from that type    or the default folder        
        if (!array_key_exists($folder->type, $unique_folders) || $folder->parentid == 0) {
            $unique_folders[$folder->type] = $folder->serverid;
        }
    }
    
    // Treo does initial sync for calendar and contacts too, so we need to fake 
    // these folders if they are not supported by the backend
    if (!array_key_exists(SYNC_FOLDER_TYPE_APPOINTMENT, $unique_folders))     
        $unique_folders[SYNC_FOLDER_TYPE_APPOINTMENT] = SYNC_FOLDER_TYPE_DUMMY;
    if (!array_key_exists(SYNC_FOLDER_TYPE_CONTACT, $unique_folders))         
        $unique_folders[SYNC_FOLDER_TYPE_CONTACT] = SYNC_FOLDER_TYPE_DUMMY;

    if (!file_put_contents(BASE_PATH.STATE_DIR."/compat-$devid", serialize($unique_folders))) {
        debugLog("_saveFolderData: Data could not be saved!");
    }
}

// returns information about folder data for a specific device    
function _getFolderID($devid, $class) {
    $filename = BASE_PATH.STATE_DIR."/compat-$devid";

    if (file_exists($filename)) {
        $arr = unserialize(file_get_contents($filename));

        if ($class == "Calendar")
            return $arr[SYNC_FOLDER_TYPE_APPOINTMENT];
        if ($class == "Contacts")
            return $arr[SYNC_FOLDER_TYPE_CONTACT];

    }

    return false;
}

/**
 * Function which converts a hex entryid to a binary entryid.
 * @param string @data the hexadecimal string
 */
function hex2bin($data)
{
    $len = strlen($data);
    $newdata = "";

    for($i = 0;$i < $len;$i += 2)
    {
        $newdata .= pack("C", hexdec(substr($data, $i, 2)));
    } 
    return $newdata;
}

function utf8_to_windows1252($string, $option = "")
{
    if (function_exists("iconv")){
        return @iconv("UTF-8", "Windows-1252" . $option, $string);
    }else{
        return utf8_decode($string); // no euro support here
    }
}

function windows1252_to_utf8($string, $option = "")
{
    if (function_exists("iconv")){
        return @iconv("Windows-1252", "UTF-8" . $option, $string);
    }else{
        return utf8_encode($string); // no euro support here
    }
}

function w2u($string) { return windows1252_to_utf8($string); }
function u2w($string) { return utf8_to_windows1252($string); }

function w2ui($string) { return windows1252_to_utf8($string, "//TRANSLIT"); }
function u2wi($string) { return utf8_to_windows1252($string, "//TRANSLIT"); }

/**
 * Truncate an UTF-8 encoded sting correctly
 * 
 * If it's not possible to truncate properly, an empty string is returned 
 *
 * @param string $string - the string
 * @param string $length - position where string should be cut
 * @return string truncated string
 */ 
function utf8_truncate($string, $length) {
    if (strlen($string) <= $length) 
        return $string;
    
    while($length >= 0) {
        if ((ord($string[$length]) < 0x80) || (ord($string[$length]) >= 0xC0))
            return substr($string, 0, $length);
        
        $length--;
    }
    return "";
}


/**
 * Build an address string from the components
 *
 * @param string $street - the street
 * @param string $zip - the zip code
 * @param string $city - the city
 * @param string $state - the state
 * @param string $country - the country
 * @return string the address string or null
 */
function buildAddressString($street, $zip, $city, $state, $country) {
    $out = "";
    
    if (isset($country) && $street != "") $out = $country;
    
    $zcs = "";
    if (isset($zip) && $zip != "") $zcs = $zip;
    if (isset($city) && $city != "") $zcs .= (($zcs)?" ":"") . $city;
    if (isset($state) && $state != "") $zcs .= (($zcs)?" ":"") . $state;
    if ($zcs) $out = $zcs . "\r\n" . $out;
    
    if (isset($street) && $street != "") $out = $street . (($out)?"\r\n\r\n". $out: "") ;
    
    return ($out)?$out:null;
}

/**
 * Checks if the PHP-MAPI extension is available and in a requested version
 *
 * @param string $version - the version to be checked ("6.30.10-18495", parts or build number)
 * @return boolean installed version is superior to the checked strin
 */
function checkMapiExtVersion($version = "") {
    // compare build number if requested
    if (preg_match('/^\d+$/',$version) && strlen > 3) {
        $vs = preg_split('/-/', phpversion("mapi"));
        return ($version <= $vs[1]); 
    }
    
    if (extension_loaded("mapi")){
        if (version_compare(phpversion("mapi"), $version) == -1){
            return false;
        }
    }
    else
        return false;
        
    return true;
}

/**
 * Parses and returns an ecoded vCal-Uid from an 
 * OL compatible GlobalObjectID
 *
 * @param string $olUid - an OL compatible GlobalObjectID
 * @return string the vCal-Uid if available in the olUid, else the original olUid as HEX
 */
function getICalUidFromOLUid($olUid){
    $icalUid = strtoupper(bin2hex($olUid));
    if(($pos = stripos($olUid,"vCal-Uid"))) {
    	$length = unpack("V", substr($olUid, $pos-4,4));
    	$icalUid = substr($olUid, $pos+12, $length[1] -14);
    }
    return $icalUid;
}

/**
 * Checks the given UID if it is an OL compatible GlobalObjectID
 * If not, the given UID is encoded inside the GlobalObjectID
 *
 * @param string $icalUid - an appointment uid as HEX
 * @return string an OL compatible GlobalObjectID
 *
 */
function getOLUidFromICalUid($icalUid) {
	if (strlen($icalUid) <= 64) {
		$len = 13 + strlen($icalUid);
		$OLUid = pack("V", $len);
		$OLUid .= "vCal-Uid";
		$OLUid .= pack("V", 1);
		$OLUid .= $icalUid;
		return hex2bin("040000008200E00074C5B7101A82E0080000000000000000000000000000000000000000". bin2hex($OLUid). "00");
	}
	else
	   return hex2bin($icalUid);
} 

/**
 * Extracts the basedate of the GlobalObjectID and the RecurStartTime 
 *
 * @param string $goid - OL compatible GlobalObjectID
 * @param long $recurStartTime - RecurStartTime 
 * @return long basedate 
 *
 */
function extractBaseDate($goid, $recurStartTime) {
    $hexbase = substr(bin2hex($goid), 32, 8);
    $day = hexdec(substr($hexbase, 6, 2));
    $month = hexdec(substr($hexbase, 4, 2));
    $year = hexdec(substr($hexbase, 0, 4));

    if ($day && $month && $year) {
		$h = $recurStartTime >> 12;
		$m = ($recurStartTime - $h * 4096) >> 6;
		$s = $recurStartTime - $h * 4096 - $m * 64;

        return gmmktime($h, $m, $s, $month, $day, $year);
    }
    else
        return false;
}
?>