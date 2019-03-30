//
//  SettingsController.swift
//  txt.rdr
//
//  Created by spoonik on 2016/06/07.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit
import Foundation


protocol SettingsControllerDelegate {
    func settingsRefresh(toBeRefreshed: Bool)
    func reserveInterfaceKeep()
    func setSystemColor(sysColId: Int)
}

class SettingsController: WKInterfaceController {

    @IBOutlet var largeFontSwitch: WKInterfaceSwitch!
  
    @IBOutlet var autoOpenBookSwitch: WKInterfaceSwitch!
  
    @IBOutlet var colorPicker: WKInterfacePicker!
  
    var largeFont: Bool = SettingsUtility.getLargeFontSizeSetting()
    var autoOpenBook: Bool = SettingsUtility.getAutoOpenBookSetting()
    var sysColId: Int = SettingsUtility.getSystemColor().0
  
    var delegate:FileListController! = nil
    var toBeRefreshed: Bool = false

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        let controller: FileListController = (context as? FileListController)!
        delegate = controller
        self.delegate.reserveInterfaceKeep()


        largeFontSwitch.setOn(largeFont)
        autoOpenBookSwitch.setOn(autoOpenBook)
      
        // Color Picker 初期化
        let systemColors = SettingsUtility.getSystemColors()
        var pickerItems: [WKPickerItem] = []
        for item in systemColors {
            let pickerItem = WKPickerItem()
            pickerItem.title = item.0
            pickerItems.append(pickerItem)
        }
        colorPicker.setItems(pickerItems)
        colorPicker.setSelectedItemIndex(sysColId)
      
    }

    @IBAction func largeFontSet(value: Bool) {
        largeFont = value
        //SettingsUtility.setLargeFontSetting(value)
        // スイッチが変更されたら即設定値を書き込む。iPhoneの設定アプリの流儀
    }
  
    @IBAction func autoOpenBookSet(value: Bool) {
        autoOpenBook = value
    }
  
    @IBAction func colorPickerChanged(value: Int) {
        if sysColId != value {
            sysColId = value
            toBeRefreshed = true
            self.delegate.setSystemColor(sysColId)
        }
    }
  
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        SettingsUtility.setSystemSettings(largeFont, sysColId: sysColId)
        SettingsUtility.setAutoOpenBookSetting(autoOpenBook)
      
        // メッセージ確認の上、ファイルを消してビューを閉じる
        self.delegate.settingsRefresh(toBeRefreshed)
      
        super.didDeactivate()
    }

}
