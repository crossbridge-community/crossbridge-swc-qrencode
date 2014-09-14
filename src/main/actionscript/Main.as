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
import crossbridge.qrencode.CModule;
import crossbridge.qrencode.vfs.ISpecialFile;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.utils.getTimer;

[SWF(width="800", height="600", backgroundColor="#999999", frameRate="60")]
public class Main extends Sprite implements ISpecialFile {
    private var bm:Bitmap;
    private var label:TextField;
    private var label2:TextField;

    public function Main() {
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
    }

    private function onAddedToStage(event:Event):void {
        stage.align = StageAlign.TOP_LEFT;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.frameRate = 60;

        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

        CModule.rootSprite = this;
        CModule.vfs.console = this;
        CModule.startAsync(this);

        label = createTextField(0, 0, 800, 30, "ClickAndEditTheText");
        label.addEventListener(KeyboardEvent.KEY_UP, runScript);
        stage.focus = label;

        label2 = createTextField(0, 570, 800, 30, "");

        runScript(null);
    }

    private function createTextField(x:int, y:int, w:int, h:int, text:String):TextField {
        var textFormat:TextFormat = new TextFormat("Arial", 14, 0xFFFFFF);
        textFormat.align = TextFormatAlign.CENTER;
        var label:TextField = new TextField();
        label.defaultTextFormat = textFormat;
        label.type = TextFieldType.INPUT;
        label.wordWrap = true;
        label.multiline = true;
        label.x = x;
        label.y = y;
        label.width = w;
        label.height = h;
        addChild(label);
        label.text = text;
        return label;
    }

    private function runScript(event:Event):void {
        var startTime:int = getTimer();
        var qrcode:QRcode = QRcode.create()
        // vers: maximum="40" minimum="1" value="15" 
        // ecc: maximum="3" value="2" 
        var vers:int = 15;
        var ecc:int = 2;
        //trace(errorCorrectionCodeName(ecc), "v" + vers);
        qrcode.swigCPtr = QREncode.QRcode_encodeString(label.text, vers, ecc, QREncode.QR_MODE_8, 1)

        if (qrcode.swigCPtr == 0 || qrcode.width <= 0) {
            throw new Error("QRCodeError");
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
            bm.bitmapData.dispose();
            removeChild(bm);
            bm = null;
        }
        bm = new Bitmap(bmd);
        // disable smoothing
        bm.smoothing = false;
        // scale up image
        bm.scaleX = bm.scaleY = 5;
        // center on stage
        bm.x = (stage.stageWidth - bm.width) * 0.5;
        bm.y = (stage.stageHeight - bm.height) * 0.5;
        // add to display list
        addChild(bm);

        var calcTime:int = getTimer() - startTime;
        const mem:Number = Number((System.totalMemoryNumber * 0.000000954).toFixed(3));
        label2.text = "Render time: " + calcTime + "ms | System Memory: " + mem + "Mb";
        System.pauseForGCIfCollectionImminent();
    }

    private function errorCorrectionCodeName(val:int):String {
        switch (val) {
            case 0:
                return "EC Level L"
            case 1:
                return "EC Level M"
            case 2:
                return "EC Level Q"
            case 3:
                return "EC Level H"
        }
        return null
    }

    // Console implementation

    /**
     * The callback to call when CrossBridge code calls the <code>posix exit()</code> function. Leave null to exit silently.
     * @private
     */
    public var exitHook:Function;

    /**
     * The PlayerKernel implementation will use this function to handle
     * C process exit requests
     */
    public function exit(code:int):Boolean {
        trace("Main::exit: " + code);

        // default to unhandled
        if (exitHook != null)
            return exitHook(code);
        else
            throw new Error("exit() called.");
    }

    /**
     * The PlayerKernel implementation uses this function to handle
     * C IO write requests to the file "/dev/tty" (for example, output from
     * printf will pass through this function). See the ISpecialFile
     * documentation for more information about the arguments and return value.
     */
    public function write(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int {
        var str:String = CModule.readString(bufPtr, nbyte);
        trace(str);
        return nbyte;
    }

    /**
     * The PlayerKernel implementation uses this function to handle
     * C IO read requests to the file "/dev/tty" (for example, reads from stdin
     * will expect this function to provide the data). See the ISpecialFile
     * documentation for more information about the arguments and return value.
     */
    public function read(fd:int, bufPtr:int, nbyte:int, errnoPtr:int):int {
        return 0;
    }

    /**
     * The PlayerKernel implementation uses this function to handle
     * C fcntl requests to the file "/dev/tty."
     * See the ISpecialFile documentation for more information about the
     * arguments and return value.
     */
    public function fcntl(fd:int, com:int, data:int, errnoPtr:int):int {
        return 0;
    }

    /**
     * The PlayerKernel implementation uses this function to handle
     * C ioctl requests to the file "/dev/tty."
     * See the ISpecialFile documentation for more information about the
     * arguments and return value.
     */
    public function ioctl(fd:int, com:int, data:int, errnoPtr:int):int {
        return CModule.callI(CModule.getPublicSymbol("vglttyioctl"), new <int>[fd, com, data, errnoPtr]);
    }
}
}