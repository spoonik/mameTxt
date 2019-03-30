//
//  SettingsUtility.swift
//  txt.rdr
//
//  Created by spoonik on 2016/06/07.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit

struct SettingsUtility {

    // DBスキーマ：キーワード群
    static let keySETTINGS = "Settings"   // plistのエントリー名
    static let keyFONTSIZE = "FontSize"
    static let keySYSTEMCOLOR = "SystemColor"
    static let keyAUTOOPENBOOK = "AutoOpenBook"
    static let keySPEECHSWITCH = "SpeechSwitch"
    static let keySPEECHSPEED = "SpeechSpeed"
    static let keySPEECHLANGUAGE = "SpeechLanguage"

    static let systemColors: [(String, UIColor)]
          = [("Yellow", UIColor(red:1.0,green:0.8,blue:0.0,alpha:1.0)),
              ("Green", UIColor(red:0,green:0.75,blue:0.2,alpha:1.0)),
              ("Blue", UIColor(red:0,green:0.6,blue:1.0,alpha:1.0)),
              ("Purple", UIColor(red:0.65,green:0.4,blue:0.9,alpha:1.0)),
              ("Pink", UIColor(red:0.9,green:0.35,blue:0.6,alpha:1.0)),
              ("Gray", UIColor(red:0.6,green:0.6,blue:0.7,alpha:1.0)),
              ]

    // Settings デフォルト値設定
    static let largeFontSize = 18
    static let normalFontSize = 16
  
    
    // Speech Synthe On/Off
    static func setSpeechSettings(speechSwitch: Bool, speed: Float, language: String) {
        let userDefaults = UserDefaults.standard
        let settingsDict = [keySPEECHSWITCH: speechSwitch,
                            keySPEECHSPEED: speed,
                            keySPEECHLANGUAGE: language] as [String : Any]
        userDefaults.set(settingsDict, forKey: keySETTINGS)
        userDefaults.synchronize()
    }
    // Speech Synthe On/Off
    static func getSpeechSettings() -> (Bool, Float, String) {
        let userDefaults = UserDefaults.standard
        let settingsDict: NSDictionary? = userDefaults.object(forKey: keySETTINGS) as? NSDictionary
        if settingsDict != nil {
            let speechSwitch: Bool? = settingsDict![keySPEECHSWITCH] as? Bool
            if speechSwitch == nil {
                return (true, 0.5, Locale.preferredLanguages[0])
            }
            let speechSpeed: Float? = settingsDict![keySPEECHSPEED] as? Float
            if speechSpeed == nil {
                return (speechSwitch!, 0.5, Locale.preferredLanguages[0])
            }
            let speechLanguage: String? = settingsDict![keySPEECHLANGUAGE] as? String
            if speechLanguage == nil {
                return (speechSwitch!, speechSpeed!, Locale.preferredLanguages[0])
            }
            return (speechSwitch!, speechSpeed!, speechLanguage!)
        }
        return (true, 0.5, Locale.preferredLanguages[0])
    }
  
    // 大きいフォント設定：plistには実フォントサイズを書き込むようにしている
    static func getFontSizeSetting() -> Int {
        let userDefaults = UserDefaults.standard
        let settingsDict: NSDictionary? = userDefaults.object(forKey: keySETTINGS) as? NSDictionary
        if settingsDict != nil {
            let id: Int? = settingsDict![keyFONTSIZE] as? Int
            if id != nil {
                return id!
            }
        }
        return normalFontSize
    }
    static func getLargeFontSizeSetting() -> Bool {
        return (getFontSizeSetting() == largeFontSize)
    }
    static func setLargeFontSetting(_ largeFont: Bool) {
        let userDefaults = UserDefaults.standard
        let fontSize = largeFont ? largeFontSize : normalFontSize
        let settingsDict = [keyFONTSIZE: fontSize]
        userDefaults.set(settingsDict, forKey: keySETTINGS)
    }
  
    //--------------------- obsoleted -----------------------
    // システムカラーの設定：廃止
    static func getSystemColors() -> [(String, UIColor)] {
        return systemColors
    }
    static func setSystemColor(_ id: Int) {
        let userDefaults = UserDefaults.standard
        let settingsDict = [keySYSTEMCOLOR: systemColors[id].1]
        userDefaults.set(settingsDict, forKey: keySETTINGS)
    }
    static func getSystemColor() -> (Int, UIColor) {
        let userDefaults = UserDefaults.standard
        let settingsDict: NSDictionary? = userDefaults.object(forKey: keySETTINGS) as? NSDictionary
        if settingsDict != nil {
            let id: Int? = settingsDict![keySYSTEMCOLOR] as? Int
            if id != nil {
                return (id!, systemColors[id!].1)
            }
        }
        return (0, systemColors[0].1)
    }
    static func getSystemColorFromId(_ id: Int) -> UIColor {
        return systemColors[id].1
    }
  
    // フォント設定とシステムカラー設定を書き込む関数：廃止
    static func setSystemSettings(_ largeFont: Bool, sysColId: Int) {
        let userDefaults = UserDefaults.standard
        let fontSize = largeFont ? largeFontSize : normalFontSize
        let settingsDict = [keyFONTSIZE: fontSize, keySYSTEMCOLOR: sysColId]
        userDefaults.set(settingsDict, forKey: keySETTINGS)
        userDefaults.synchronize()
    }
  
    // 自動的にブックをオープンするかどうかの設定：廃止
    static func getAutoOpenBookSetting() -> Bool {
        let userDefaults = UserDefaults.standard
        let settingsDict: NSDictionary? = userDefaults.object(forKey: keySETTINGS) as? NSDictionary
        if settingsDict != nil {
            let id: Bool? = settingsDict![keyAUTOOPENBOOK] as? Bool
            if id != nil {
                return id!
            }
        }
        return false
    }
    static func setAutoOpenBookSetting(_ autoOpen: Bool) {
        let userDefaults = UserDefaults.standard
        let settingsDict = [keyAUTOOPENBOOK: autoOpen]
        userDefaults.set(settingsDict, forKey: keySETTINGS)
    }
}
