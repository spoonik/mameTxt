//
//  BookDBUtility.swift
//  txt.rdr
//
//  Created by spoonik on 2016/04/17.
//  Copyright © 2016年 spoonikapps. All rights reserved.
//

import WatchKit


// plistにDBを書き込むためのstaticなユーティリティクラス

struct BookDBUtility {

    // DBスキーマ：キーワード群
  
    static let keyTOC = "TOC"   // plistのエントリー名
  
    // 以下はStringのDictionaryに変換するときのキーワード群
    static let keyFILENAME = "FileName"
    static let keyBOOKMARK = "BookmarkPageIndex"
    static let keyFILELENGTH = "FileLength"
    static let keyPAGEPOS = "PagePos"
    static let keyPAGEPOSSEP = ","
    static let keySHUFFLEMODE = "ShuffleMode"
    static let keyAUTOFLIPSPEED = "AutoFlipSpeed"
    static let keyLANGUAGE = "Language"
    static let keyREADINGSPEED = "ReadingSpeed"

  
    // plist実体ファイルからUserDefaultsに展開・保存する
    // Apple Watch再起動時、UserDefaultsが消えてしまう問題に対策
    static func loadPlist() -> NSArray? {
        let docsDir: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let plistFileName = docsDir + "/TOC.plist"
        if FileManager.default.fileExists(atPath: plistFileName) {
            return NSArray(contentsOfFile: plistFileName)!
        }

        return nil
    }
    static func writePlist(_ toctable: Array<BookInfo>) {
        let docsDir: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let plistFileName = docsDir + "/TOC.plist"
        let toctabletemp: NSArray = convertTocToNSArray(toctable)
        toctabletemp.write(toFile: plistFileName, atomically: true)
    }

    // plistからTOC情報を読み込んで、Arrayとして返す
    static func getTocController() -> Array<BookInfo> {
        var toctable: Array<BookInfo> = []
      
        let userDefaults = UserDefaults.standard //(suiteName: "group.com.spoonikapps.txtrdr")
        var toctabletemp: NSArray? = userDefaults.object(forKey: keyTOC) as? NSArray

        if toctabletemp == nil {
            toctabletemp = loadPlist()
        }
      
        if toctabletemp != nil {
            toctable = convertNSArrayToToc(toctabletemp!)
        }
      
        return toctable
    }
  
    // TOCのArrayを渡して、plistに書き込む
    static func saveTocController(_ toctable: Array<BookInfo>, syncnow: Bool) {
        let userDefaults = UserDefaults.standard  //(suiteName: "group.com.spoonikapps.txtrdr")
        let toctabletemp: NSArray = convertTocToNSArray(toctable)
        userDefaults.set(toctabletemp, forKey: keyTOC)
        if syncnow {
            userDefaults.synchronize()
            writePlist(toctable)
        }
    }
  
    // plistには提携の情報しか書き込めないため、String:StringのDictionaryのNSArrayに
    // BookInfoを変換して返す
    // convertNSArrayToTocと対になるようにメンテナンスすること！
    static func convertTocToNSArray(_ toctable: Array<BookInfo>) -> NSArray {
        let array: NSMutableArray = []
        for oneToc: BookInfo in toctable {
            var oneTocDic: Dictionary<String, String> = [:]
            oneTocDic[keyFILENAME] = oneToc.filename
            oneTocDic[keyBOOKMARK] = String(oneToc.bookmark)
            oneTocDic[keyFILELENGTH] = String(oneToc.filesize)
            oneTocDic[keySHUFFLEMODE] = String(oneToc.shufflemode)
            oneTocDic[keyAUTOFLIPSPEED] = String(oneToc.autoflipspeed)
            oneTocDic[keyLANGUAGE] = String(oneToc.lang)
            oneTocDic[keyREADINGSPEED] = String(oneToc.reading_speed)

            var pagepos: String = ""
            for pos in oneToc.pagepos {
                pagepos += String(pos) + keyPAGEPOSSEP
            }
            oneTocDic[keyPAGEPOS] = pagepos
          
            array.add(oneTocDic)
        }
        return array
    }

    // NSArrayの状態をBookInfoのArrayに変換して返す
    // convertTocToNSArrayと対になるようにメンテナンスすること！
    static func convertNSArrayToToc(_ plist: NSArray) -> Array<BookInfo> {
        var array: Array<BookInfo> = []
        for element in plist {
            let oneTocDic: Dictionary<String, String> = element as! Dictionary<String, String>
            let oneToc = BookInfo()
          
            oneToc.filename = String(validatingUTF8: oneTocDic[keyFILENAME]!)!
            oneToc.filesize = UInt64(oneTocDic[keyFILELENGTH]!)!
            oneToc.bookmark = Int(oneTocDic[keyBOOKMARK]!)!
          
            let pageposstr: String = String(validatingUTF8: oneTocDic[keyPAGEPOS]!)!
            let pageposstrarr = pageposstr.components(separatedBy: keyPAGEPOSSEP)

            oneToc.pagepos = []
            for pos in pageposstrarr {
                if !pos.isEmpty {
                    oneToc.pagepos.append(Int(pos)!)
                }
            }

            // V1.0になかった辞書情報 ///////////////////////////////////////////
            if let value: String = oneTocDic[keySHUFFLEMODE] {   // V1.1
                oneToc.shufflemode = Int(value)!
            } else {
                oneToc.shufflemode = oneToc.NORMALMODE
            }
            
            if let value: String = oneTocDic[keyAUTOFLIPSPEED] {   // V2.1
                oneToc.autoflipspeed = Int(value)!
            } else {
                oneToc.autoflipspeed = 0
            }
            
            if let value: String = oneTocDic[keyLANGUAGE] {   // V4.1
                oneToc.lang = value
            }
            if let value: String = oneTocDic[keyREADINGSPEED] {   // V4.1
                oneToc.reading_speed = Float(value)!
            }

            // V1.0になかった辞書情報 ///////////////////////////////////////////
          

            if oneToc.isValid() {
                // 不完全な情報はArrayに追加しない
                array.append(oneToc)
            }
        }
        return array
    }

}
