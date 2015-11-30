<?php
/***********************************************
* File      :   wbxmlencoder.php
* Project   :   Z-Push
* Descr     :   WBXMLEncoder encodes to Wap Binary XML
*
* Created   :   01.10.2007
*
* Copyright 2007 - 2013 Zarafa Deutschland GmbH
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero General Public License, version 3,
* as published by the Free Software Foundation with the following additional
* term according to sec. 7:
*
* According to sec. 7 of the GNU Affero General Public License, version 3,
* the terms of the AGPL are supplemented with the following terms:
*
* "Zarafa" is a registered trademark of Zarafa B.V.
* "Z-Push" is a registered trademark of Zarafa Deutschland GmbH
* The licensing of the Program under the AGPL does not imply a trademark license.
* Therefore any rights, title and interest in our trademarks remain entirely with us.
*
* However, if you propagate an unmodified version of the Program you are
* allowed to use the term "Z-Push" to indicate that you distribute the Program.
* Furthermore you may use our trademarks where it is necessary to indicate
* the intended purpose of a product or service provided you use it in accordance
* with honest practices in industrial or commercial matters.
* If you want to propagate modified versions of the Program under the name "Z-Push",
* you may only do so if you have a written permission by Zarafa Deutschland GmbH
* (to acquire a permission please contact Zarafa at trademark@zarafa.com).
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU Affero General Public License for more details.
*
* You should have received a copy of the GNU Affero General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
* Consult LICENSE file for details
************************************************/


class WBXMLEncoder extends WBXMLDefs {
    private $_dtd;
    private $_out;
    private $_outLog;

    private $_tagcp;
    private $_attrcp;

    private $logStack = array();

    // We use a delayed output mechanism in which we only output a tag when it actually has something
    // in it. This can cause entire XML trees to disappear if they don't have output data in them; Ie
    // calling 'startTag' 10 times, and then 'endTag' will cause 0 bytes of output apart from the header.

    // Only when content() is called do we output the current stack of tags

    private $_stack;

    private $multipart; // the content is multipart
    private $bodyparts;

    public function WBXMLEncoder($output, $multipart = false) {
        // make sure WBXML_DEBUG is defined. It should be at this point
        if (!defined('WBXML_DEBUG')) define('WBXML_DEBUG', false);

        $this->_out = $output;
        $this->_outLog = StringStreamWrapper::Open("");

        $this->_tagcp = 0;
        $this->_attrcp = 0;

        // reverse-map the DTD
        foreach($this->dtd["namespaces"] as $nsid => $nsname) {
            $this->_dtd["namespaces"][$nsname] = $nsid;
        }

        foreach($this->dtd["codes"] as $cp => $value) {
            $this->_dtd["codes"][$cp] = array();
            foreach($this->dtd["codes"][$cp] as $tagid => $tagname) {
                $this->_dtd["codes"][$cp][$tagname] = $tagid;
            }
        }
        $this->_stack = array();
        $this->multipart = $multipart;
        $this->bodyparts = array();
    }

    /**
     * Puts the WBXML header on the stream
     *
     * @access public
     * @return
     */
    public function startWBXML() {
        if ($this->multipart) {
            header("Content-Type: application/vnd.ms-sync.multipart");
            ZLog::Write(LOGLEVEL_DEBUG, "WBXMLEncoder->startWBXML() type: vnd.ms-sync.multipart");
        }
        else {
            header("Content-Type: application/vnd.ms-sync.wbxml");
            ZLog::Write(LOGLEVEL_DEBUG, "WBXMLEncoder->startWBXML() type: vnd.ms-sync.wbxml");
        }

        $this->outByte(0x03); // WBXML 1.3
        $this->outMBUInt(0x01); // Public ID 1
        $this->outMBUInt(106); // UTF-8
        $this->outMBUInt(0x00); // string table length (0)
    }

    /**
     * Puts a StartTag on the output stack
     *
     * @param $tag
     * @param $attributes
     * @param $nocontent
     *
     * @access public
     * @return
     */
    public function startTag($tag, $attributes = false, $nocontent = false) {
        $stackelem = array();

        if(!$nocontent) {
            $stackelem['tag'] = $tag;
            $stackelem['attributes'] = $attributes;
            $stackelem['nocontent'] = $nocontent;
            $stackelem['sent'] = false;

            array_push($this->_stack, $stackelem);

            // If 'nocontent' is specified, then apparently the user wants to force
            // output of an empty tag, and we therefore output the stack here
        } else {
            $this->_outputStack();
            $this->_startTag($tag, $attributes, $nocontent);
        }
    }

    /**
     * Puts an EndTag on the stack
     *
     * @access public
     * @return
     */
    public function endTag() {
        $stackelem = array_pop($this->_stack);

        // Only output end tags for items that have had a start tag sent
        if($stackelem['sent']) {
            $this->_endTag();

            if(count($this->_stack) == 0)
                ZLog::Write(LOGLEVEL_DEBUG, "WBXMLEncoder->endTag() WBXML output completed");

            if(count($this->_stack) == 0 && $this->multipart == true) {
                $this->processMultipart();
            }
            if(count($this->_stack) == 0)
                $this->writeLog();
        }
    }

    /**
     * Puts content on the output stack.
     *
     * @param string $content
     *
     * @access public
     * @return
     */
    public function content($content) {
        // We need to filter out any \0 chars because it's the string terminator in WBXML. We currently
        // cannot send \0 characters within the XML content anywhere.
        $content = str_replace("\0","",$content);

        if("x" . $content == "x")
            return;
        $this->_outputStack();
        $this->_content($content);
    }

    /**
     * Puts content of a stream on the output stack.
     *
     * @param resource $stream
     * @param boolean $asBase64     if true, the data will be encoded as base64, default: false
     *
     * @access public
     * @return
     */
    public function contentStream($stream, $asBase64 = false) {
        if (!$asBase64) {
            include_once('lib/wbxml/replacenullcharfilter.php');
            $rnc_filter = stream_filter_append($stream, 'replacenullchar');
        }

        $this->_outputStack();
        $this->_contentStream($stream, $asBase64);

        if (!$asBase64) {
            stream_filter_remove($rnc_filter);
        }
    }

    /**
     * Gets the value of multipart
     *
     * @access public
     * @return boolean
     */
    public function getMultipart() {
        return $this->multipart;
    }

    /**
     * Adds a bodypart
     *
     * @param Stream $bp
     *
     * @access public
     * @return void
     */
    public function addBodypartStream($bp) {
        if ($this->multipart)
            $this->bodyparts[] = $bp;
    }

    /**
     * Gets the number of bodyparts
     *
     * @access public
     * @return int
     */
    public function getBodypartsCount() {
        return count($this->bodyparts);
    }

    /**----------------------------------------------------------------------------------------------------------
     * Private WBXMLEncoder stuff
     */

    /**
     * Output any tags on the stack that haven't been output yet
     *
     * @access private
     * @return
     */
    private function _outputStack() {
        for($i=0;$i<count($this->_stack);$i++) {
            if(!$this->_stack[$i]['sent']) {
                $this->_startTag($this->_stack[$i]['tag'], $this->_stack[$i]['attributes'], $this->_stack[$i]['nocontent']);
                $this->_stack[$i]['sent'] = true;
            }
        }
    }

    /**
     * Outputs an actual start tag
     *
     * @access private
     * @return
     */
    private function _startTag($tag, $attributes = false, $nocontent = false) {
        $this->logStartTag($tag, $attributes, $nocontent);

        $mapping = $this->getMapping($tag);

        if(!$mapping)
            return false;

        if($this->_tagcp != $mapping["cp"]) {
            $this->outSwitchPage($mapping["cp"]);
            $this->_tagcp = $mapping["cp"];
        }

        $code = $mapping["code"];
        if(isset($attributes) && is_array($attributes) && count($attributes) > 0) {
            $code |= 0x80;
        }

        if(!isset($nocontent) || !$nocontent)
            $code |= 0x40;

        $this->outByte($code);

        if($code & 0x80)
            $this->outAttributes($attributes);
    }

    /**
     * Outputs actual data.
     *
     * @access private
     * @param string $content
     * @return
     */
    private function _content($content) {
        $this->logContent($content);
        $this->outByte(WBXML_STR_I);
        $this->outTermStr($content);
    }

    /**
     * Outputs actual data coming from a stream, optionally encoded as base64.
     *
     * @access private
     * @param resource $stream
     * @param boolean  $asBase64
     * @return
     */
    private function _contentStream($stream, $asBase64) {
        // write full stream, including the finalizing terminator to the output stream (stuff outTermStr() would do)
        $this->outByte(WBXML_STR_I);
        fseek($stream, 0, SEEK_SET);
        if ($asBase64) {
            $out_filter = stream_filter_append($this->_out, 'convert.base64-encode');
        }
        $written = stream_copy_to_stream($stream, $this->_out);
        if ($asBase64) {
            stream_filter_remove($out_filter);
        }
        fwrite($this->_out, chr(0));

        // data is out, do some logging
        $stat = fstat($stream);
        $logContent = sprintf("<<< written %d of %d bytes of %s data >>>", $written, $stat['size'], $asBase64 ? "base64 encoded":"plain");
        $this->logContent($logContent);

        // write the meta data also to the _outLog stream, WBXML_STR_I was already written by outByte() above
        fwrite($this->_outLog, $logContent);
        fwrite($this->_outLog, chr(0));
    }

    /**
     * Outputs an actual end tag
     *
     * @access private
     * @return
     */
    private function _endTag() {
        $this->logEndTag();
        $this->outByte(WBXML_END);
    }

    /**
     * Outputs a byte
     *
     * @param $byte
     *
     * @access private
     * @return
     */
    private function outByte($byte) {
        fwrite($this->_out, chr($byte));
        fwrite($this->_outLog, chr($byte));
    }

    /**
     * Outputs a string table
     *
     * @param $uint
     *
     * @access private
     * @return
     */
    private function outMBUInt($uint) {
        while(1) {
            $byte = $uint & 0x7f;
            $uint = $uint >> 7;
            if($uint == 0) {
                $this->outByte($byte);
                break;
            } else {
                $this->outByte($byte | 0x80);
            }
        }
    }

    /**
     * Outputs content with string terminator
     *
     * @param $content
     *
     * @access private
     * @return
     */
    private function outTermStr($content) {
        fwrite($this->_out, $content);
        fwrite($this->_out, chr(0));

        // truncate data bigger than 10 KB on outLog
        $l = strlen($content);
        if ($l > 10240) {
            $content = substr($content, 0, 5120) . sprintf("...<data with total %d bytes truncated>...", $l) . substr($content, -5120);
        }
        fwrite($this->_outLog, $content);
        fwrite($this->_outLog, chr(0));
    }

    /**
     * Output attributes
     * We don't actually support this, because to do so, we would have
     * to build a string table before sending the data (but we can't
     * because we're streaming), so we'll just send an END, which just
     * terminates the attribute list with 0 attributes.
     *
     * @access private
     * @return
     */
    private function outAttributes() {
        $this->outByte(WBXML_END);
    }

    /**
     * Switches the codepage
     *
     * @param $page
     *
     * @access private
     * @return
     */
    private function outSwitchPage($page) {
        $this->outByte(WBXML_SWITCH_PAGE);
        $this->outByte($page);
    }

    /**
     * Get the mapping for a tag
     *
     * @param $tag
     *
     * @access private
     * @return array
     */
    private function getMapping($tag) {
        $mapping = array();

        $split = $this->splitTag($tag);

        if(isset($split["ns"])) {
            $cp = $this->_dtd["namespaces"][$split["ns"]];
        }
        else {
            $cp = 0;
        }

        $code = $this->_dtd["codes"][$cp][$split["tag"]];

        $mapping["cp"] = $cp;
        $mapping["code"] = $code;

        return $mapping;
    }

    /**
     * Split a tag from a the fulltag (namespace + tag)
     *
     * @param $fulltag
     *
     * @access private
     * @return array        keys: 'ns' (namespace), 'tag' (tag)
     */
    private function splitTag($fulltag) {
        $ns = false;
        $pos = strpos($fulltag, chr(58)); // chr(58) == ':'

        if($pos) {
            $ns = substr($fulltag, 0, $pos);
            $tag = substr($fulltag, $pos+1);
        }
        else {
            $tag = $fulltag;
        }

        $ret = array();
        if($ns)
            $ret["ns"] = $ns;
        $ret["tag"] = $tag;

        return $ret;
    }

    /**
     * Logs a StartTag to ZLog
     *
     * @param $tag
     * @param $attr
     * @param $nocontent
     *
     * @access private
     * @return
     */
    private function logStartTag($tag, $attr, $nocontent) {
        if(!WBXML_DEBUG)
            return;

        $spaces = str_repeat(" ", count($this->logStack));
        if($nocontent)
            ZLog::Write(LOGLEVEL_WBXML,"O " . $spaces . " <$tag/>");
        else {
            array_push($this->logStack, $tag);
            ZLog::Write(LOGLEVEL_WBXML,"O " . $spaces . " <$tag>");
        }
    }

    /**
     * Logs a EndTag to ZLog
     *
     * @access private
     * @return
     */
    private function logEndTag() {
        if(!WBXML_DEBUG)
            return;

        $spaces = str_repeat(" ", count($this->logStack));
        $tag = array_pop($this->logStack);
        ZLog::Write(LOGLEVEL_WBXML,"O " . $spaces . "</$tag>");
    }

    /**
     * Logs content to ZLog
     *
     * @param string $content
     *
     * @access private
     * @return
     */
    private function logContent($content) {
        if(!WBXML_DEBUG)
            return;

        $spaces = str_repeat(" ", count($this->logStack));
        ZLog::Write(LOGLEVEL_WBXML,"O " . $spaces . $content);
    }

    /**
     * Processes the multipart response
     *
     * @access private
     * @return void
     */
    private function processMultipart() {
        ZLog::Write(LOGLEVEL_DEBUG, sprintf("WBXMLEncoder->processMultipart() with %d parts to be processed", $this->getBodypartsCount()));
        $len = ob_get_length();
        $buffer = ob_get_clean();
        $nrBodyparts = $this->getBodypartsCount();
        $blockstart = (($nrBodyparts + 1) * 2) * 4 + 4;

        $data = pack("iii", ($nrBodyparts + 1), $blockstart, $len);

        ob_start(null, 1048576);

        foreach ($this->bodyparts as $bp) {
            $blockstart = $blockstart + $len;
            $len = fstat($bp);
            $len = (isset($len['size'])) ? $len['size'] : 0;
            $data .= pack("ii", $blockstart, $len);
        }

        fwrite($this->_out, $data);
        fwrite($this->_out, $buffer);
        fwrite($this->_outLog, $data);
        fwrite($this->_outLog, $buffer);

        foreach($this->bodyparts as $bp) {
            while (!feof($bp)) {
                $out = fread($bp, 4096);
                fwrite($this->_out, $out);
                fwrite($this->_outLog, $out);
            }
        }
    }

    /**
     * Writes the sent WBXML data to the log if it is not bigger than 512K.
     *
     * @access private
     * @return void
     */
    private function writeLog() {
        $stat = fstat($this->_outLog);
        if ($stat['size'] < 524288) {
            $data = base64_encode(stream_get_contents($this->_outLog, -1,0));
        }
        else {
            $data = "more than 512K of data";
        }
        ZLog::Write(LOGLEVEL_WBXML, "WBXML-OUT: ". $data, false);
    }
}

?>