//
//  QuotedParagraphControllerInterfaceController.swift
//  txt.rdr
//
//  Created by spoonik on 2016/05/02.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation


class QuotedParagraphControllerInterfaceController: WKInterfaceController {

    // 値を呼び出し側に戻すためのdelegate
    var delegate:PageJumpControllerDelegate! = nil
    var pageController: TextPageController! = nil
    var quotePage = 0
  
    @IBOutlet var textBox: WKInterfaceLabel!
  
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        pageController = (context as? TextPageController)!
        delegate = pageController

        // Quoteをシャッフルして表示
        reShuffle()
    }

    // 表示したQuoteを含むページにジャンプ
    @IBAction func jumpToPage() {
        delegate.jumpDidFinish(Float(quotePage))
        popController()
    }
    
    // もう一度シャッフルして、新しいQuoteを表示
    @IBAction func reShuffle() {
        var text = ""
        (text, quotePage) = (pageController.bookInfo?.getShuffledParagraph())!
        textBox.setText("\"" + text + "\"")
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
