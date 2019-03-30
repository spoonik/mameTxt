//
//  PageJumpController.swift
//  txt.rdr
//
//  Created by spoonik on 2016/04/16.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation

protocol PageJumpControllerDelegate {
    func jumpDidFinish(_ context:Float)
}


// ページジャンプ位置を指定するためのダイアログ:
// Sliderを表示に使い、かつPickerを使って、デジタルクラウンでページ位置を指定させたいため
// やや面倒くさいことをしている。Pickerの値変更をSliderに反映させる方法をとる

class PageJumpController: WKInterfaceController {

    @IBOutlet var label: WKInterfaceLabel!
    @IBOutlet var slider: WKInterfaceSlider!
    @IBOutlet var picker: WKInterfacePicker!
    var delegate:PageJumpControllerDelegate! = nil
  
    let sliderMax: Int = 10000   //StoryBoardの設定を合わせること！
    
    var maxPageNum: Int = 1
    var currentPageNum: Int = 0
    var selectedPageNum: Int = 0
    var transferValue: Bool = false //pickerとsliderを同期させるトリッキーな変数
  
  
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        let pageController: TextPageController = (context as? TextPageController)!
        currentPageNum = (pageController.bookInfo?.bookmark)!
        maxPageNum = (pageController.bookInfo?.pagepos.count)!-1    //最大ページはマイナス1
        delegate = pageController
      
        redisplayPageNumInfo()
    }

    @IBAction func sliderValueChanged(_ value: Float) {
        let fvalue = Float(currentPageNum) * Float(sliderMax) / Float(maxPageNum)
        if transferValue {
            transferValue = false
            return
        }

        if value > fvalue {
            currentPageNum = min(maxPageNum+1, currentPageNum+1)
        }
        else if value < fvalue {
            currentPageNum = max(currentPageNum-1, 0)
        }

        picker.setSelectedItemIndex(currentPageNum)
      
        redisplayPageNumInfo()
    }
    @IBAction func pickerValueChanged(_ value: Int) {
        let fvalue = Float(value) * Float(sliderMax) / Float(maxPageNum)
      
        currentPageNum = value
        transferValue = true
        slider.setValue(fvalue)
        sliderValueChanged(fvalue)
        redisplayPageNumInfo()
    }
  
    func redisplayPageNumInfo() {
        label.setText("\(currentPageNum)/\(maxPageNum)")
    }
  
    @IBAction func pushJump() {
        delegate.jumpDidFinish(Float(currentPageNum))
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        let items = [WKPickerItem](repeating: WKPickerItem(), count: maxPageNum+1)
        picker.focus()
        picker.setItems(items)
        picker.setSelectedItemIndex(currentPageNum)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }


}
