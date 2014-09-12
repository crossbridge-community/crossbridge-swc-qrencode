/*
 * =BEGIN MIT LICENSE
 * 
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 The CrossBridge Team
 * https://github.com/crossbridge-community
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * =END MIT LICENSE
 *
 */
package {
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFieldType;

import sample.qrencode.CModule;
import sample.qrencode.*;
import sample.qrencode.vfs.ISpecialFile;

import flash.display.Sprite;

[SWF(width="800", height="600", backgroundColor="#333333", frameRate="60")]
public class Main extends Sprite /*implements ISpecialFile*/ {

    internal var uic:Sprite;
    internal var bm:Bitmap;

    private var srctext:TextField;

    public function Main() {
        addEventListener(Event.ADDED_TO_STAGE, appInit);
    }

    internal function appInit(event:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, appInit);

        CModule.rootSprite = this
        //CModule.vfs.console = this
        CModule.startAsync(this)

        srctext = new TextField();
        srctext.type = TextFieldType.INPUT;
        srctext.wordWrap = true;
        srctext.multiline = true;
        srctext.y = 300;
        srctext.width = 800;
        srctext.height = 300;
        addChild(srctext);
        srctext.text = "HelloQRCode";
        
        uic = new Sprite()
        addChild(uic)  

        runScript(null)
    }

    internal function runScript(event:Event):void {
        var qrcode:QRcode = QRcode.create()
        // vers: maximum="40" minimum="1" value="15" 
        // ecc: maximum="3" value="2" 
        var vers:int = 15;
        var ecc:int = 2;
        qrcode.swigCPtr = QREncode.QRcode_encodeString(srctext.text, vers, ecc, QREncode.QR_MODE_8, 1)

        if (qrcode.swigCPtr == 0 || qrcode.width <= 0) {
            trace("QRError");
            return;
        }

        var bmd:BitmapData = new BitmapData(qrcode.width, qrcode.width, false, 0xAAAAAA)
        var d:int = qrcode.data
        for (var y:int = 0; y < qrcode.width; y++) {
            for (var x:int = 0; x < qrcode.width; x++) {
                bmd.setPixel(x, y, CModule.read8(d++) & 1 ? 0x0 : 0xFFFFFF)
            }
        }

        if (bm) {
            uic.removeChild(bm)
        }
        bm = new Bitmap(bmd)
        bm.smoothing = false
        bm.scaleX = bm.scaleY = 2
        uic.addChild(bm)
    }

    private function errorCorrectionCodeName(val:String):String {
        switch (val) {
            case "0":
                return "EC Level L"
            case "1":
                return "EC Level M"
            case "2":
                return "EC Level Q"
            case "3":
                return "EC Level H"
        }
        return null
    }

    private function versionTip(val:String):String {
        return "Version: " + val
    }

    public function output(s:String):void {
    }

    public function write(fd:int, buf:int, nbyte:int, errno_ptr:int):int {
        var str:String = CModule.readString(buf, nbyte);
        output(str);
        return nbyte;
    }

    public function read(fd:int, buf:int, nbyte:int, errno_ptr:int):int {
        return 0
    }
}
}